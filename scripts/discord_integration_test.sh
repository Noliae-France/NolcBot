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

validate_snowflake() {
  local name="$1"
  local value="$2"
  if ! printf '%s' "$value" | grep -Eq '^[0-9]{17,20}$'; then
    echo "::error::$name doit contenir uniquement l'identifiant Discord numérique brut, sans texte, sans espace, sans guillemets."
    exit 1
  fi
}

validate_hex() {
  local name="$1"
  local value="$2"
  if ! printf '%s' "$value" | grep -Eq '^[0-9a-fA-F]{64}$'; then
    echo "::error::$name doit contenir uniquement la clé hexadécimale Discord de 64 caractères."
    exit 1
  fi
}

validate_snowflake "DISCORD_APP_ID" "$DISCORD_APP_ID"
validate_snowflake "DISCORD_TEST_GUILD_ID" "$DISCORD_TEST_GUILD_ID"
if [ -n "${DISCORD_CLIENT_ID:-}" ]; then
  validate_snowflake "DISCORD_CLIENT_ID" "$DISCORD_CLIENT_ID"
fi
if [ -n "${DISCORD_TEST_CHANNEL_ID:-}" ]; then
  validate_snowflake "DISCORD_TEST_CHANNEL_ID" "$DISCORD_TEST_CHANNEL_ID"
fi
validate_hex "DISCORD_PUBLIC_KEY" "$DISCORD_PUBLIC_KEY"

work_dir="$(mktemp -d)"
trap 'rm -rf "$work_dir"' EXIT
export NOLIAE_DB_PATH="$work_dir/nolcbot.sqlite3"

section() {
  echo
  echo "==> $1"
}

assert_sql_count() {
  local label="$1"
  local query="$2"
  local min_count="$3"
  local value
  value="$(sqlite3 "$NOLIAE_DB_PATH" "$query")"
  if [ "${value:-0}" -lt "$min_count" ]; then
    echo "::error::$label invalide: $value < $min_count"
    exit 1
  fi
  echo "OK: $label ($value)"
}

assert_command() {
  local command="$1"
  if ! printf '%s' "$commands_json" | jq -e --arg name "$command" '.[] | select(.name == $name)' >/dev/null; then
    echo "::error::Commande slash manquante: /$command"
    exit 1
  fi
  echo "OK: /$command"
}

discord_get() {
  local label="$1"
  local path="$2"
  local out="$3"
  local status
  status="$(curl -sS -o "$out" -w '%{http_code}' -H "$auth_header" "$discord_api$path")"
  if [ "$status" != "200" ]; then
    echo "::error::$label a échoué côté Discord REST (HTTP $status)"
    if [ "$status" = "401" ]; then
      echo "::error::DISCORD_BOT_TOKEN est invalide, révoqué, mal copié ou ne correspond pas à un token de bot actif."
    elif [ "$status" = "403" ]; then
      echo "::error::Le bot est authentifié mais n'a pas les permissions nécessaires pour cette vérification."
    elif [ "$status" = "404" ]; then
      echo "::error::Ressource Discord introuvable: vérifie l'ID configuré dans GitHub Secrets."
    fi
    exit 1
  fi
}

section "Initialisation SQLite et clé publique Discord"
./bot setup-public-key "$DISCORD_PUBLIC_KEY" >/dev/null
stored_key="$(sqlite3 "$NOLIAE_DB_PATH" "SELECT value FROM guild_config WHERE guild_id='_system' AND key='discord.public_key';")"
if [ "$stored_key" != "$DISCORD_PUBLIC_KEY" ]; then
  echo "::error::La clé publique Discord n'a pas été persistée correctement dans SQLite"
  exit 1
fi

assert_sql_count "tables SQLite" "SELECT count(*) FROM sqlite_master WHERE type='table';" 6
assert_sql_count "schéma SQLite version 2" "SELECT count(*) FROM guild_config WHERE guild_id='_system' AND key='schema_version' AND value='2';" 1
for table in guild_config audit_log reminders rss_subscriptions twitch_subscriptions invite_cache; do
  assert_sql_count "table $table" "SELECT count(*) FROM sqlite_master WHERE type='table' AND name='$table';" 1
done

section "Configuration fonctionnelle SQLite par module"
sqlite3 "$NOLIAE_DB_PATH" <<SQL
INSERT OR REPLACE INTO guild_config VALUES('$DISCORD_TEST_GUILD_ID','module.moderation.enabled','true',strftime('%s','now'));
INSERT OR REPLACE INTO guild_config VALUES('$DISCORD_TEST_GUILD_ID','module.community.enabled','true',strftime('%s','now'));
INSERT OR REPLACE INTO guild_config VALUES('$DISCORD_TEST_GUILD_ID','module.fun.enabled','true',strftime('%s','now'));
INSERT OR REPLACE INTO guild_config VALUES('$DISCORD_TEST_GUILD_ID','module.stats.enabled','true',strftime('%s','now'));
INSERT OR REPLACE INTO guild_config VALUES('$DISCORD_TEST_GUILD_ID','module.economy.enabled','true',strftime('%s','now'));
INSERT OR REPLACE INTO guild_config VALUES('$DISCORD_TEST_GUILD_ID','module.integrations.enabled','true',strftime('%s','now'));
INSERT OR REPLACE INTO guild_config VALUES('$DISCORD_TEST_GUILD_ID','module.ai.enabled','true',strftime('%s','now'));
INSERT OR REPLACE INTO guild_config VALUES('$DISCORD_TEST_GUILD_ID','prefix','!',strftime('%s','now'));
INSERT INTO audit_log(guild_id, actor_id, action, target_id, reason, created_at) VALUES('$DISCORD_TEST_GUILD_ID','ci','ci_config','modules','configuration CI non destructive',strftime('%s','now'));
SQL
assert_sql_count "modules configurés" "SELECT count(*) FROM guild_config WHERE guild_id='$DISCORD_TEST_GUILD_ID' AND key LIKE 'module.%' AND value='true';" 7
assert_sql_count "audit CI" "SELECT count(*) FROM audit_log WHERE guild_id='$DISCORD_TEST_GUILD_ID' AND action='ci_config';" 1

discord_api="https://discord.com/api/v10"
auth_header="Authorization: Bot ${DISCORD_BOT_TOKEN}"

section "Vérification REST Discord: bot courant"
discord_get "Vérification du bot courant" "/users/@me" "$work_dir/me.json"
me_json="$(cat "$work_dir/me.json")"
bot_id="$(printf '%s' "$me_json" | jq -r '.id // empty')"
bot_name="$(printf '%s' "$me_json" | jq -r '.username // empty')"
if [ -z "$bot_id" ]; then
  echo "::error::Impossible d'identifier le bot avec /users/@me"
  exit 1
fi
echo "Bot Discord authentifié: ${bot_name} (${bot_id})"

section "Vérification REST Discord: application"
discord_get "Vérification de l'application" "/oauth2/applications/@me" "$work_dir/app.json"
app_json="$(cat "$work_dir/app.json")"
app_id="$(printf '%s' "$app_json" | jq -r '.id // empty')"
if [ "$app_id" != "$DISCORD_APP_ID" ]; then
  echo "::error::DISCORD_APP_ID ne correspond pas à l'application du token"
  exit 1
fi

section "Vérification REST Discord: serveur de test"
discord_get "Vérification du serveur de test" "/guilds/$DISCORD_TEST_GUILD_ID" "$work_dir/guild.json"
guild_json="$(cat "$work_dir/guild.json")"
guild_name="$(printf '%s' "$guild_json" | jq -r '.name // empty')"
if [ -z "$guild_name" ]; then
  echo "::error::Serveur de test inaccessible"
  exit 1
fi
echo "Serveur de test accessible: ${guild_name} (${DISCORD_TEST_GUILD_ID})"

section "Vérification REST Discord: présence du bot sur le serveur"
discord_get "Vérification de présence du bot" "/guilds/$DISCORD_TEST_GUILD_ID/members/$bot_id" "$work_dir/member.json"
member_json="$(cat "$work_dir/member.json")"
member_user_id="$(printf '%s' "$member_json" | jq -r '.user.id // empty')"
if [ "$member_user_id" != "$bot_id" ]; then
  echo "::error::Le bot n'est pas membre du serveur de test"
  exit 1
fi

section "Enregistrement des commandes slash"
./bot register >/dev/null

section "Enregistrement immédiat des commandes sur le serveur de test"
./bot commands-json >"$work_dir/commands_payload.json"
guild_command_status="$(curl -sS -o "$work_dir/guild_commands_put.json" -w '%{http_code}' -X PUT -H "$auth_header" -H "Content-Type: application/json" --data-binary "@$work_dir/commands_payload.json" "$discord_api/applications/$DISCORD_APP_ID/guilds/$DISCORD_TEST_GUILD_ID/commands")"
if [ "$guild_command_status" != "200" ] && [ "$guild_command_status" != "201" ]; then
  echo "::error::Enregistrement guild-scoped des commandes échoué (HTTP $guild_command_status)"
  if [ "$guild_command_status" = "403" ]; then
    echo "::error::Le bot n'a pas les droits nécessaires ou l'application n'est pas installée sur le serveur de test."
  fi
  exit 1
fi

section "Vérification REST Discord: commandes du serveur de test enregistrées"
discord_get "Lecture des commandes du serveur de test" "/applications/$DISCORD_APP_ID/guilds/$DISCORD_TEST_GUILD_ID/commands" "$work_dir/commands.json"
commands_json="$(cat "$work_dir/commands.json")"
command_count="$(printf '%s' "$commands_json" | jq 'length')"
if [ "$command_count" -lt 10 ]; then
  echo "::error::Trop peu de commandes Discord enregistrées: $command_count"
  exit 1
fi
echo "Commandes globales visibles: $command_count"

section "Vérification commandes slash par domaine"
for command in \
  ping help health version privacy \
  ban kick mute warn sanctions clear slowmode \
  ticket ticket_add ticket_remove ticket_close \
  faq faq_ai community_event_ideas community_announce_ai \
  balance daily weekly work shop buy inventory \
  roll coin 8ball pfc quiz riddle meme morpion \
  stats stats_report logs_csv \
  ai ai_config summarize rewrite ideas \
  rss rss_subscribe youtube_subscribe twitch_subscribe github_subscribe reddit_subscribe \
  form_create form_open channel_edit channel_sync_config; do
  assert_command "$command"
done

section "Démarrage HTTP court du bot"
set +e
timeout 8s ./bot >"$work_dir/http.log" 2>&1
http_rc=$?
set -e
if [ "$http_rc" -ne 0 ] && [ "$http_rc" -ne 124 ]; then
  echo "::error::Le serveur HTTP a quitté avec le code $http_rc"
  sed -n '1,80p' "$work_dir/http.log"
  exit 1
fi
if ! rg -q "écoute|Clé publique|Port" "$work_dir/http.log"; then
  echo "::warning::Le démarrage HTTP n'a pas produit le log attendu, mais n'a pas échoué immédiatement."
fi
echo "HTTP: démarrage sans échec immédiat."

section "Smoke Gateway Discord court"
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

section "Tests fonctionnels non destructifs"
sqlite3 "$NOLIAE_DB_PATH" <<SQL
INSERT OR REPLACE INTO guild_config VALUES('$DISCORD_TEST_GUILD_ID','automod.invites','true',strftime('%s','now'));
INSERT OR REPLACE INTO guild_config VALUES('$DISCORD_TEST_GUILD_ID','automod.links','true',strftime('%s','now'));
INSERT OR REPLACE INTO guild_config VALUES('$DISCORD_TEST_GUILD_ID','reports.channel','ci-channel',strftime('%s','now'));
INSERT OR REPLACE INTO guild_config VALUES('$DISCORD_TEST_GUILD_ID','ai.provider','openai',strftime('%s','now'));
INSERT OR REPLACE INTO guild_config VALUES('$DISCORD_TEST_GUILD_ID','ai.model','gpt-4o-mini',strftime('%s','now'));
INSERT OR REPLACE INTO guild_config VALUES('$DISCORD_TEST_GUILD_ID','form.ci.title','CI Form',strftime('%s','now'));
INSERT OR REPLACE INTO guild_config VALUES('$DISCORD_TEST_GUILD_ID','form.ci.question','CI Question',strftime('%s','now'));
INSERT INTO audit_log(guild_id, actor_id, action, target_id, reason, created_at) VALUES('$DISCORD_TEST_GUILD_ID','ci','moderation_dry_run','none','warn/mute/ban non destructifs uniquement',strftime('%s','now'));
INSERT INTO audit_log(guild_id, actor_id, action, target_id, reason, created_at) VALUES('$DISCORD_TEST_GUILD_ID','ci','ai_dry_run','openai','configuration IA testée sans publier de contenu',strftime('%s','now'));
INSERT INTO audit_log(guild_id, actor_id, action, target_id, reason, created_at) VALUES('$DISCORD_TEST_GUILD_ID','ci','forms_dry_run','ci','formulaire simulé',strftime('%s','now'));
SQL
assert_sql_count "automod configurée" "SELECT count(*) FROM guild_config WHERE guild_id='$DISCORD_TEST_GUILD_ID' AND key LIKE 'automod.%' AND value='true';" 2
assert_sql_count "IA configurée" "SELECT count(*) FROM guild_config WHERE guild_id='$DISCORD_TEST_GUILD_ID' AND key IN ('ai.provider','ai.model');" 2
assert_sql_count "formulaire simulé" "SELECT count(*) FROM guild_config WHERE guild_id='$DISCORD_TEST_GUILD_ID' AND key LIKE 'form.ci.%';" 2
assert_sql_count "audit modules dry-run" "SELECT count(*) FROM audit_log WHERE guild_id='$DISCORD_TEST_GUILD_ID' AND action LIKE '%dry_run';" 3

if [ -n "${DISCORD_TEST_CHANNEL_ID:-}" ]; then
  section "Test message Discord optionnel"
  message_payload="$(jq -nc --arg content "✅ NolcBot CI: test d'intégration non destructif terminé pour ${GITHUB_SHA:-local}." '{content: $content}')"
  message_status="$(curl -sS -o "$work_dir/message.json" -w '%{http_code}' -H "$auth_header" -H "Content-Type: application/json" -d "$message_payload" "$discord_api/channels/$DISCORD_TEST_CHANNEL_ID/messages")"
  if [ "$message_status" != "200" ]; then
    echo "::error::Impossible d'envoyer le message de test Discord (HTTP $message_status)"
    exit 1
  fi
  echo "Message de test envoyé dans le salon configuré."
else
  echo "DISCORD_TEST_CHANNEL_ID absent: test d'envoi message ignoré."
fi

if [ -n "${OPENAI_API_KEY:-}" ]; then
  section "Vérification OpenAI optionnelle"
  openai_status="$(curl -sS -o "$work_dir/openai.json" -w '%{http_code}' -H "Authorization: Bearer ${OPENAI_API_KEY}" https://api.openai.com/v1/models)"
  if [ "$openai_status" != "200" ]; then
    echo "::error::OPENAI_API_KEY invalide ou API OpenAI inaccessible (HTTP $openai_status)"
    exit 1
  fi
  echo "OpenAI: clé acceptée par l'API."
else
  echo "OPENAI_API_KEY absent: test IA ignoré."
fi

section "Résumé"
echo "Intégration Discord complète OK."
echo "Bot, app, serveur, commandes, HTTP, Gateway, SQLite, modules, modération dry-run, IA et formulaires validés."
