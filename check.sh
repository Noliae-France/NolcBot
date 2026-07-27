#!/bin/sh
set -eu

nolc pkg install
nolc check .
nolc check tests/time.nol
nolc test tests/time.nol
nolc check tests/acl.nol
nolc test tests/acl.nol
nolc check tests/integrations.nol
OPENSSL_PREFIX="${OPENSSL_PREFIX:-$(brew --prefix openssl@3 2>/dev/null || true)}"
set -- nolc test tests/integrations.nol --lien ssl --lien crypto
if [ -n "$OPENSSL_PREFIX" ]; then
    set -- "$@" --chemin-include "$OPENSSL_PREFIX/include" --chemin-lib "$OPENSSL_PREFIX/lib"
fi
"$@"

nolc check tests/automod.nol
nolc test tests/automod.nol
nolc check tests/forms.nol
nolc test tests/forms.nol
nolc check tests/store.nol
store_test_dir=$(mktemp -d "${TMPDIR:-/tmp}/noliae-store.XXXXXX")
(cd "$store_test_dir" && nolc build "$OLDPWD/tests/store.nol" -o store-test --lien sqlite3 && NOLIAE_DB_PATH="$store_test_dir/store.sqlite3" ./store-test)
./build.sh

smoke_dir=$(mktemp -d "${TMPDIR:-/tmp}/noliae-check.XXXXXX")
NOLIAE_DB_PATH="$smoke_dir/noliae.sqlite3" ./bot >"$smoke_dir/bot.log" 2>&1 || true
test -f "$smoke_dir/noliae.sqlite3"
test "$(sqlite3 "$smoke_dir/noliae.sqlite3" 'PRAGMA integrity_check;')" = "ok"
test "$(sqlite3 "$smoke_dir/noliae.sqlite3" "SELECT value FROM guild_config WHERE guild_id='_system' AND key='schema_version';")" = "2"
test "$(sqlite3 "$smoke_dir/noliae.sqlite3" "SELECT count(*) FROM sqlite_master WHERE type='table' AND name='reminders';")" = "1"
test "$(sqlite3 "$smoke_dir/noliae.sqlite3" "SELECT count(*) FROM sqlite_master WHERE type='table' AND name='rss_subscriptions';")" = "1"
test "$(sqlite3 "$smoke_dir/noliae.sqlite3" "SELECT count(*) FROM sqlite_master WHERE type='table' AND name='twitch_subscriptions';")" = "1"
test "$(sqlite3 "$smoke_dir/noliae.sqlite3" "SELECT count(*) FROM sqlite_master WHERE type='table' AND name='invite_cache';")" = "1"

sqlite3 "$smoke_dir/legacy.sqlite3" "CREATE TABLE guild_config (guild_id TEXT NOT NULL, key TEXT NOT NULL, value TEXT NOT NULL, updated_at INTEGER NOT NULL, PRIMARY KEY (guild_id,key)); CREATE TABLE audit_log (id INTEGER PRIMARY KEY AUTOINCREMENT, guild_id TEXT NOT NULL, actor_id TEXT NOT NULL, action TEXT NOT NULL, target_id TEXT, reason TEXT, created_at INTEGER NOT NULL); INSERT INTO guild_config VALUES('_system','schema_version','1',strftime('%s','now'));"
NOLIAE_DB_PATH="$smoke_dir/legacy.sqlite3" ./bot >"$smoke_dir/legacy.log" 2>&1 || true
test "$(sqlite3 "$smoke_dir/legacy.sqlite3" "SELECT value FROM guild_config WHERE guild_id='_system' AND key='schema_version';")" = "2"
test "$(sqlite3 "$smoke_dir/legacy.sqlite3" "SELECT count(*) FROM sqlite_master WHERE type='table' AND name='reminders';")" = "1"
test "$(sqlite3 "$smoke_dir/legacy.sqlite3" "SELECT count(*) FROM sqlite_master WHERE type='table' AND name='rss_subscriptions';")" = "1"
test "$(sqlite3 "$smoke_dir/legacy.sqlite3" "SELECT count(*) FROM sqlite_master WHERE type='table' AND name='twitch_subscriptions';")" = "1"
test "$(sqlite3 "$smoke_dir/legacy.sqlite3" "SELECT count(*) FROM sqlite_master WHERE type='table' AND name='invite_cache';")" = "1"

if rg -o '"name":"[a-z0-9_-]+"' src/commands.nol | sort | uniq -d | rg . >/dev/null; then
    echo "Erreur: commande slash dupliquée dans src/commands.nol" >&2
    exit 1
fi

echo "Vérifications Nolc et build natif réussis."
