#!/bin/sh
set -eu

repo="${NOLCBOT_UPDATE_REPO:-Noliae-France/NolcBot}"
api_url="https://api.github.com/repos/$repo/releases/latest"
asset_name="${NOLCBOT_UPDATE_ASSET:-nolcbot-linux}"
install_path="${NOLCBOT_INSTALL_PATH:-./bot}"
work_dir="$(mktemp -d "${TMPDIR:-/tmp}/nolcbot-update.XXXXXX")"

cleanup() {
  rm -rf "$work_dir"
}
trap cleanup EXIT INT TERM

need() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Erreur: commande requise manquante: $1" >&2
    exit 1
  fi
}

need curl
need jq

echo "==> Recherche de la dernière release GitHub: $repo"
release_json="$work_dir/release.json"
curl -fsSL \
  -H "Accept: application/vnd.github+json" \
  -H "User-Agent: NolcBot-Updater/1.0" \
  "$api_url" > "$release_json"

tag="$(jq -r '.tag_name // empty' "$release_json")"
asset_url="$(jq -r --arg name "$asset_name" '.assets[]? | select(.name == $name) | .browser_download_url' "$release_json" | head -n 1)"
checksum_url="$(jq -r --arg name "$asset_name.sha256" '.assets[]? | select(.name == $name) | .browser_download_url' "$release_json" | head -n 1)"

if [ -z "$tag" ] || [ -z "$asset_url" ] || [ -z "$checksum_url" ]; then
  echo "Erreur: release incomplète. Attendu: $asset_name et $asset_name.sha256" >&2
  exit 1
fi

echo "==> Release trouvée: $tag"
curl -fsSL -o "$work_dir/$asset_name" "$asset_url"
curl -fsSL -o "$work_dir/$asset_name.sha256" "$checksum_url"

echo "==> Vérification SHA-256"
if command -v sha256sum >/dev/null 2>&1; then
  expected="$(awk '{print $1}' "$work_dir/$asset_name.sha256")"
  actual="$(sha256sum "$work_dir/$asset_name" | awk '{print $1}')"
else
  need shasum
  expected="$(awk '{print $1}' "$work_dir/$asset_name.sha256")"
  actual="$(shasum -a 256 "$work_dir/$asset_name" | awk '{print $1}')"
fi

if [ "$expected" != "$actual" ]; then
  echo "Erreur: checksum invalide, installation annulée." >&2
  exit 1
fi

chmod +x "$work_dir/$asset_name"
install_dir="$(dirname "$install_path")"
mkdir -p "$install_dir"

if [ -f "$install_path" ]; then
  backup="$install_path.backup.$(date +%Y%m%d%H%M%S)"
  echo "==> Backup: $backup"
  cp "$install_path" "$backup"
fi

echo "==> Installation: $install_path"
cp "$work_dir/$asset_name" "$install_path"
chmod +x "$install_path"

if [ -n "${NOLCBOT_SYSTEMD_SERVICE:-}" ]; then
  echo "==> Redémarrage systemd: $NOLCBOT_SYSTEMD_SERVICE"
  systemctl restart "$NOLCBOT_SYSTEMD_SERVICE"
fi

echo "==> NolcBot mis à jour vers $tag"
