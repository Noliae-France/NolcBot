#!/bin/sh
set -eu

source_db="${1:?Usage: ./restore.sh sauvegarde.sqlite3 [destination.sqlite3]}"
destination="${2:-./noliae-discord.sqlite3}"
if [ ! -f "$source_db" ]; then
    echo "Sauvegarde absente : $source_db" >&2
    exit 1
fi
sqlite3 "$source_db" ".backup '$destination'"
echo "Base restaurée : $destination"
