#!/usr/bin/env bash
set -euo pipefail

mask_if_present() {
  local value="${1:-}"
  if [ -n "$value" ]; then
    echo "::add-mask::$value"
  fi
}

mask_if_present "${DISCORD_BOT_TOKEN:-}"
mask_if_present "${DISCORD_PUBLIC_KEY:-}"
mask_if_present "${DISCORD_CLIENT_SECRET:-}"
mask_if_present "${OPENAI_API_KEY:-}"

required=(
  DISCORD_APP_ID
  DISCORD_BOT_TOKEN
  DISCORD_PUBLIC_KEY
  DISCORD_TEST_GUILD_ID
)

missing=0
for name in "${required[@]}"; do
  if [ -z "${!name:-}" ]; then
    echo "::error::$name manquant dans GitHub Secrets"
    missing=1
  fi
done
if [ "$missing" -ne 0 ]; then
  exit 1
fi

work_dir="$(mktemp -d)"
trap 'rm -rf "$work_dir"' EXIT
export NOLIAE_DB_PATH="$work_dir/nolcbot.sqlite3"

echo "Initialisation SQLite et clé publique Discord..."
./bot setup-public-key "$DISCORD_PUBLIC_KEY" >/dev/null
stored_key="$(sqlite3 "$NOLIAE_DB_PATH" "SELECT value FROM guild_config WHERE guild_id='_system' AND key='discord.public_key';")"
if [ "$stored_key" != "$DISCORD_PUBLIC_KEY" ]; then
  echo "::error::La clé publique Discord n'a pas été persistée correctement dans SQLite"
  exit 1
fi

discord_api="https://discord.com/api/v10"
auth_header="Authorization: Bot ${DISCORD_BOT_TOKEN}"

echo "Vérification REST Discord: bot courant..."
me_json="$(curl -fsS -H "$auth_header" "$discord_api/users/@me")"
bot_id="$(printf '%s' "$me_json" | jq -r '.id // empty')"
bot_name="$(printf '%s' "$me_json" | jq -r '.username // empty')"
if [ -z "$bot_id" ]; then
  echo "::error::Impossible d'identifier le bot avec /users/@me"
  exit 1
fi
echo "Bot Discord authentifié: ${bot_name} (${bot_id})"

echo "Vérification REST Discord: application..."
app_json="$(curl -fsS -H "$auth_header" "$discord_api/oauth2/applications/@me")"
app_id="$(printf '%s' "$app_json" | jq -r '.id // empty')"
if [ "$app_id" != "$DISCORD_APP_ID" ]; then
  echo "::error::DISCORD_APP_ID ne correspond pas à l'application du token"
  exit 1
fi

echo "Vérification REST Discord: serveur de test..."
guild_json="$(curl -fsS -H "$auth_header" "$discord_api/guilds/$DISCORD_TEST_GUILD_ID")"
guild_name="$(printf '%s' "$guild_json" | jq -r '.name // empty')"
if [ -z "$guild_name" ]; then
  echo "::error::Serveur de test inaccessible"
  exit 1
fi
echo "Serveur de test accessible: ${guild_name} (${DISCORD_TEST_GUILD_ID})"

echo "Vérification REST Discord: présence du bot sur le serveur..."
member_json="$(curl -fsS -H "$auth_header" "$discord_api/guilds/$DISCORD_TEST_GUILD_ID/members/$bot_id")"
member_user_id="$(printf '%s' "$member_json" | jq -r '.user.id // empty')"
if [ "$member_user_id" != "$bot_id" ]; then
  echo "::error::Le bot n'est pas membre du serveur de test"
  exit 1
fi

echo "Enregistrement des commandes slash..."
./bot register >/dev/null

echo "Vérification REST Discord: commandes globales enregistrées..."
commands_json="$(curl -fsS -H "$auth_header" "$discord_api/applications/$DISCORD_APP_ID/commands")"
command_count="$(printf '%s' "$commands_json" | jq 'length')"
if [ "$command_count" -lt 10 ]; then
  echo "::error::Trop peu de commandes Discord enregistrées: $command_count"
  exit 1
fi
echo "Commandes globales visibles: $command_count"

echo "Smoke Gateway Discord court..."
set +e
timeout 20s ./bot gateway >"$work_dir/gateway.log" 2>&1
gateway_rc=$?
set -e
if [ "$gateway_rc" -ne 0 ] && [ "$gateway_rc" -ne 124 ]; then
  echo "::error::Le Gateway a quitté avec le code $gateway_rc"
  sed -n '1,80p' "$work_dir/gateway.log"
  exit 1
fi
echo "Gateway: connexion lancée sans échec immédiat."

if [ -n "${OPENAI_API_KEY:-}" ]; then
  echo "Vérification OpenAI optionnelle..."
  openai_status="$(curl -sS -o "$work_dir/openai.json" -w '%{http_code}' -H "Authorization: Bearer ${OPENAI_API_KEY}" https://api.openai.com/v1/models)"
  if [ "$openai_status" != "200" ]; then
    echo "::error::OPENAI_API_KEY invalide ou API OpenAI inaccessible (HTTP $openai_status)"
    exit 1
  fi
  echo "OpenAI: clé acceptée par l'API."
else
  echo "OPENAI_API_KEY absent: test IA ignoré."
fi

echo "Intégration Discord complète OK."
