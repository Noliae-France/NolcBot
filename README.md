# nolc-discord

Client **Discord** pour [Nolc](https://github.com/Noliae-France/nolc), livré comme
**paquet** (pas dans le cœur du langage). Couvre les deux voies d'accès Discord :

- **Interactions HTTP** (slash-commands, boutons, menus, modales) avec
  vérification **Ed25519** — réexporte les helpers stdlib `discord.nol` /
  `discord_sodium.nol`.
- **Gateway WebSocket** (réception **temps réel** : messages, events) — apporte
  le **côté client** que la stdlib `websocket.nol` (orientée serveur) ne fournit
  pas : handshake client, frames sortantes **masquées**, parse des frames
  serveur, machine d'état HELLO/IDENTIFY/heartbeat/dispatch.

## Installation

```sh
nolc pkg add nolc-discord --git https://github.com/Noliae-France/nolc-discord.git
# ou en local pour développer côte à côte :
nolc pkg add nolc-discord --chemin ../nolc-discord
nolc pkg install
```

Un seul import donne accès à tout :

```nolc
import "nolc-discord::src/lib.nol"
```

Compilation d'un programme qui l'utilise : `--lien sodium --lien ssl --lien crypto`
(+ chemins OpenSSL/libsodium sur macOS). Le paquet est **auto-contenu** : il
vendorise les modules stdlib dont il dépend dans `vendor/`.

### Installer nolc (binaire souverain Noliae, S3 OVH)

```bash
curl -fsSL https://noliae-nolc.s3.gra.io.cloud.ovh.net/nolc-latest-linux-x86_64.tar.gz | tar -xz
sudo install -m 0755 nolc /usr/local/bin/nolc
```

Aussi : `…-amd64.deb`, `…-x86_64.rpm` sur le même bucket. `.github/workflows/build.yml`
compile le selftest **sur le runner self-hosted Noliae** en tirant nolc de ce S3.

## API principale

| Fonction | Rôle |
|----------|------|
| `discord_dispatch(req, handler)` | Route une interaction (PING / slash-command) |
| `discord_reponse_message(txt)` / `_ephemere(txt)` / `_pong()` | Réponses d'interaction |
| `discord_verifie_ou_401(req, cle_pub_hex)` | Pré-middleware de vérification Ed25519 |
| `discord_enregistrer_commandes(app_id, token, corps_json)` | Enregistre les slash-commands (REST) |
| `discord_envoie_message(token, salon, contenu)` | Poste un message (REST) |
| `gateway_run(token, intents, on_event)` | Boucle Gateway ; `on_event(js) -> Bool` reçoit chaque dispatch |
| `ws_handshake_client` / `ws_frame_client*` / `ws_parse_serveur` | Primitives WebSocket client |

Le handler Gateway reçoit le **payload JSON complet** de chaque événement
(`{"t":...,"d":...}`) ; à l'application de filtrer sur `t` (ex. `MESSAGE_CREATE`)
et d'agir. Voir un exemple complet dans
[Example-Discord-Bot](https://github.com/Noliae-France/Example-Discord-Bot).

## Arborescence

```
nolc.toml
src/
  lib.nol       agrégateur (un import réexporte tout)
  ws_client.nol côté client WebSocket (handshake, frames masquées, parse serveur)
  gateway.nol   machine d'état Gateway (générique, handler par callback)
  rest.nol      client REST Discord sur TLS (enregistrement + envoi de messages)
vendor/         modules stdlib nolc vendorisés (+ tls_lire_bytes)
examples/
  selftest.nol  vérifie que la surface compile et lie
```

## État

- ✅ Interactions HTTP + vérification Ed25519.
- ✅ Gateway : handshake TLS+WS, HELLO/IDENTIFY/heartbeat/dispatch — validé en
  live contre `gateway.discord.gg` (le chemin authentifié complet nécessite un
  vrai token de bot).
- ⚠️ Non couverts (faciles à ajouter au-dessus) : RESUME/reconnexion, sharding,
  cache d'état, endpoints REST additionnels.
