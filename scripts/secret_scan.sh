#!/bin/sh
set -eu

tmp="${TMPDIR:-/tmp}/noliae-secret-scan.$$"
trap 'rm -f "$tmp"' EXIT

git ls-files -z >"$tmp"

echo "Scan anti-secrets des fichiers versionnés..."

fail=0

scan() {
    label="$1"
    pattern="$2"
    if xargs -0 rg -n --hidden -S -- "$pattern" <"$tmp"; then
        echo "Erreur: motif secret détecté: $label" >&2
        fail=1
    fi
}

# Tokens Discord bot les plus courants : ancien format et variantes MFA.
scan "Discord bot token" '([MN][A-Za-z0-9_\-]{23,28}\.[A-Za-z0-9_\-]{6,7}\.[A-Za-z0-9_\-]{27,})|(mfa\.[A-Za-z0-9_\-]{80,})'

# Clés privées PEM/OpenSSH.
scan "private key" '-----BEGIN (RSA |DSA |EC |OPENSSH |PGP )?PRIVATE KEY-----'

# Webhooks Discord réels.
scan "Discord webhook" 'https://(discord|discordapp)\.com/api/webhooks/[0-9]{15,25}/[A-Za-z0-9_\-]{40,}'

# Clés connues de fournisseurs externes.
scan "OpenAI API key" 'sk-[A-Za-z0-9]{20,}'
scan "GitHub token" 'github_pat_[A-Za-z0-9_]{20,}|gh[pousr]_[A-Za-z0-9_]{30,}'
scan "Google API key" 'AIza[0-9A-Za-z_\-]{35}'
scan "AWS access key" 'AKIA[0-9A-Z]{16}'

# Affectations dangereuses avec une valeur non vide et non placeholder.
if xargs -0 rg -n --hidden -S -- '(TOKEN|SECRET|PASSWORD|API_KEY|CLIENT_SECRET|WEBHOOK_URL)[A-Z0-9_]*[[:space:]]*=[[:space:]]*["'\'']?[^"'\'']{8,}' <"$tmp" \
    | rg -v '^scripts/secret_scan\.sh:' \
    | rg -v '=[[:space:]]*["'\'']?(\.\.\.|xxx|XXX|changeme|CHANGE_ME|example|EXAMPLE|placeholder|PLACEHOLDER)|DISCORD_BOT_TOKEN=$|DISCORD_APP_ID=$'; then
    echo "Erreur: variable de secret non vide détectée." >&2
    fail=1
fi

if [ "$fail" -ne 0 ]; then
    echo "Scan anti-secrets échoué." >&2
    exit 1
fi

echo "Scan anti-secrets OK."
