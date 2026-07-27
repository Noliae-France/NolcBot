# Déploiement production

## Préparer l’hôte

Le bot doit être exécuté avec un utilisateur système dédié et une base SQLite dans un répertoire inscriptible par cet utilisateur.

```sh
sudo useradd --system --home /opt/noliae-discord --shell /usr/sbin/nologin noliae
sudo install -d -o noliae -g noliae /opt/noliae-discord /var/lib/noliae-discord /etc/noliae-discord
```

Copier le binaire compilé dans `/opt/noliae-discord/bot`, puis créer `/etc/noliae-discord/bot.env` avec des permissions `0600` :

```sh
sudo chmod 600 /etc/noliae-discord/bot.env
```

Les seules variables obligatoires sont `DISCORD_APP_ID` et `DISCORD_BOT_TOKEN`. Ne jamais les mettre dans Git ou les logs. La clé publique Discord est enregistrée une seule fois dans SQLite.

Après compilation, initialiser la clé publique depuis la page **General Information** de l’application Discord :

```sh
cd /var/lib/noliae-discord
/opt/noliae-discord/bot setup-public-key VOTRE_CLE_PUBLIQUE_DISCORD
```

## Service systemd

```sh
sudo install -m 0644 deploy/noliae.service.example /etc/systemd/system/noliae-discord.service
sudo systemctl daemon-reload
sudo systemctl enable --now noliae-discord
sudo systemctl status noliae-discord
journalctl -u noliae-discord -f
```

## Sauvegarde automatique

Les sauvegardes manuelles restent disponibles avec `./backup.sh`. Pour activer une sauvegarde quotidienne résiliente aux arrêts de la machine :

```sh
sudo install -m 0644 deploy/noliae-backup.service.example /etc/systemd/system/noliae-backup.service
sudo install -m 0644 deploy/noliae-backup.timer.example /etc/systemd/system/noliae-backup.timer
sudo install -d -o noliae -g noliae /var/backups/noliae-discord
sudo systemctl daemon-reload
sudo systemctl enable --now noliae-backup.timer
systemctl list-timers noliae-backup.timer
```

Le timer lance `backup.sh` chaque jour à 03:15 UTC, avec délai aléatoire de 15 minutes et rattrapage après redémarrage (`Persistent=true`). `NOLIAE_BACKUP_KEEP` conserve les 30 dernières sauvegardes par défaut; augmentez cette valeur selon votre politique d’archivage.

L’endpoint HTTP doit être placé derrière un reverse proxy HTTPS. Le proxy doit transmettre les requêtes POST sans modifier le corps, sinon la vérification Ed25519 Discord échouera. Le binaire expose aussi `/dashboard` et `/metrics` au format Prometheus; ces routes ne révèlent aucun secret.

La page `/dashboard` fournit une interface multi-serveurs pour sélectionner un serveur, consulter ses clés non sensibles et enregistrer une configuration. Le secret saisi dans le navigateur n’est pas stocké par le bot. L’API sous-jacente passe par `GET /admin/guilds`, `GET /admin/schema`, `GET /admin/config?guild=ID`, `POST /admin/config` et `POST /admin/config/delete`, protégés par l’en-tête `X-Noliae-Admin` et la variable `NOLIAE_DASHBOARD_SECRET` (32 caractères minimum). Les corps JSON attendus sont `{"guild":"ID","key":"prefix","value":"?"}` et `{"guild":"ID","key":"prefix"}`. Les secrets et clés système sont refusés ; chaque écriture ou suppression est auditée.

## Sauvegardes

```sh
NOLIAE_BACKUP_DIR=/var/backups/noliae-discord NOLIAE_BACKUP_KEEP=30 /opt/noliae-discord/backup.sh
```

Tester régulièrement une restauration sur une copie isolée :

```sh
./restore.sh /var/backups/noliae-discord/noliae-*.sqlite3 /tmp/noliae-restore.sqlite3
sqlite3 /tmp/noliae-restore.sqlite3 'PRAGMA integrity_check;'
```

Une restauration de production se fait service arrêté, après conservation de l’ancienne base :

```sh
sudo systemctl stop noliae-discord
# conserver l’ancienne base avant remplacement
sudo systemctl start noliae-discord
```

## Vérifications

Avant chaque mise en production, exécuter `./check.sh`. Cette commande compile, exécute les tests Nolc, démarre un smoke test sans secrets et vérifie `PRAGMA integrity_check` sur le schéma SQLite. Après démarrage, vérifier `/health`, les journaux systemd et l’enregistrement des commandes avec `./bot register`.
