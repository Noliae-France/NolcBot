#!/bin/sh
set -eu

db_path="${NOLIAE_DB_PATH:-./noliae-discord.sqlite3}"
backup_dir="${NOLIAE_BACKUP_DIR:-./backups}"
keep="${NOLIAE_BACKUP_KEEP:-30}"
if [ ! -f "$db_path" ]; then
    echo "Base absente : $db_path" >&2
    exit 1
fi
case "$keep" in
    ''|*[!0-9]*) echo "NOLIAE_BACKUP_KEEP doit être un entier positif" >&2; exit 1 ;;
esac
if [ "$keep" -lt 1 ]; then
    echo "NOLIAE_BACKUP_KEEP doit être au moins égal à 1" >&2
    exit 1
fi
mkdir -p "$backup_dir"
stamp=$(date -u +%Y%m%dT%H%M%SZ)
destination="$backup_dir/noliae-$stamp.sqlite3"
sqlite3 "$db_path" ".backup '$destination'"
find "$backup_dir" -maxdepth 1 -type f -name 'noliae-*.sqlite3' -print | sort -r | tail -n +$((keep + 1)) | while IFS= read -r old_backup; do
    [ -z "$old_backup" ] || rm -f -- "$old_backup"
done
echo "Sauvegarde créée : $destination"
