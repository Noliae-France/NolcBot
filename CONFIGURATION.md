# Configuration par serveur

Toutes les clés ci-dessous sont stockées dans SQLite avec l’identifiant du serveur. Elles se règlent avec `/config clé valeur`, se listent sans valeurs avec `/config_list`, se lisent avec `/config_get clé` et se retirent avec `/config_delete clé`.

| Clé | Valeurs | Fonction |
| --- | --- | --- |
| `welcome_channel` | ID de salon | Salon de bienvenue |
| `goodbye_channel` | ID de salon | Salon de départ |
| `welcome_message` | texte, `{user}` | Message de bienvenue |
| `goodbye_message` | texte, `{user}` | Message de départ |
| `auto_role` | ID de rôle | Rôle appliqué à l’arrivée |
| `automod.invites` | `true` / `false` | Bloque les invitations Discord |
| `maintenance` | `true` / `false` | Met le serveur en maintenance ; les administrateurs conservent l’accès aux commandes |
| `_system.health.last_tick` | géré par le bot | Dernier tick Gateway observé, exposé dans `/health` et `/metrics` |
| `log.channel` | ID de salon | Salon de logs général du serveur |
| `log.moderation_channel` | ID de salon | Logs de modération, repli vers le salon général |
| `log.security_channel` | ID de salon | Logs de sécurité/automodération, repli vers le général |
| `log.community_channel` | ID de salon | Logs de signalements et communauté, repli vers le général |
| `community.ai.plan.<user>` | géré par le bot | Brouillon temporaire d’annonce, règles ou onboarding avant `/community_confirm` |
| `partnership.channel` | ID de salon | Salon de publication automatique des partenariats acceptés |
| `invites.tracking` | `true` / `false` | Observe automatiquement les utilisations d’invitations toutes les 5 minutes |
| `automod.links` | `true` / `false` | Bloque les liens HTTP(S) |
| `automod.caps` | `true` / `false` | Bloque les messages à 70 % de majuscules (au moins 8 lettres) |
| `automod.mentions` | `true` / `false` | Bloque les messages contenant au moins 5 mentions |
| `automod.banned_words` | mots séparés par des virgules | Supprime les messages contenant un terme configuré |
| `automod.duplicates` | `true` / `false` | Supprime les doublons consécutifs d’un même utilisateur |
| `antispam.max_messages` | entier, `0` désactive | Messages autorisés par fenêtre |
| `antispam.window_seconds` | entier positif | Fenêtre anti-spam |
| `moderation.warn_threshold` | entier, `0` désactive | Nombre d’avertissements avant timeout automatique |
| `moderation.warn_timeout_seconds` | 1 à 2419200 | Durée du timeout automatique après le seuil |
| `ratelimit.max_commands` | entier, `0` désactive | Commandes autorisées par fenêtre et utilisateur |
| `ratelimit.window_seconds` | entier positif | Fenêtre de commandes |
| `raid.join_limit` | entier, `0` désactive | Arrivées déclenchant l’anti-raid |
| `raid.window_seconds` | entier positif | Fenêtre anti-raid |
| `raid.action` | `passive` / `kick` | Action anti-raid |
| `xp.enabled` | `true` / `false` | Attribution d’XP par message |
| `economy.*` | géré par le bot | Soldes et récompenses économiques |
| `prefix` | texte court | Préfixe des commandes Gateway |
| `ai.enabled` | `true` / `false` | Active ou désactive `/ai` pour ce serveur |
| `ai.provider` | `openai` / `gemini` / `mistral` | Fournisseur IA configuré avec `/ai_config` |
| `ai.api_key` | secret | Clé API du fournisseur IA ; masquée dans `/config_list` |
| `ai.model` | texte | Modèle IA configuré avec `/ai_config` |
| `ai.mod.plan.<user>` | géré par le bot | Proposition temporaire de l’assistant modération avant confirmation humaine |
| `ai.admin.plan.<user>` | géré par le bot | Plan temporaire de l’assistant administrateur avant confirmation humaine |
| `translate.enabled` | `true` / `false` | Active ou désactive `/translate` pour ce serveur |
| `xp.role.<niveau>` | ID de rôle Discord | Rôle attribué à l’atteinte du niveau indiqué |
| `tickets.max_per_day` | entier, `0` désactive | Nombre maximal de tickets ouverts par utilisateur sur 24 h |
| `voice.role_seconds` | entier positif | Seuil de temps vocal cumulé avant attribution |
| `voice.role_id` | ID de rôle Discord | Rôle attribué au seuil vocal |
| `voice.temp_category` | ID de catégorie Discord | Catégorie des salons vocaux temporaires |
| `reports.channel` | ID de salon | Active les rapports statistiques automatiques |
| `overlay.title` | texte | Titre affiché sur l’overlay stream |
| `overlay.subtitle` | texte | Sous-titre affiché sur l’overlay stream |
| `overlay.accent` | couleur CSS courte | Couleur principale de l’overlay, ex. `#6674ff` |
| `overlay.position` | `bottom-left`, `bottom-right`, `top-left`, `top-right`, `center` | Position de l’overlay |
| `overlay.width` | 260 à 900 | Largeur de l’overlay en pixels |
| `overlay.opacity` | 0.1 à 1 | Opacité du panneau overlay |
| `voice.temp.<salon>` | géré par le bot | Registre interne des salons temporaires créés |
| `ticket.category_id` | ID de catégorie Discord | Catégorie des tickets, configurable avec `/channel_sync_config` |
| `ticket.staff_role_id` | ID de rôle Discord | Rôle staff autorisé dans les tickets |
| `form.<nom>.title` | texte ≤ 45 caractères | Titre d’un formulaire Discord |
| `form.<nom>.label` | texte ≤ 45 caractères | Question affichée dans le modal |
| `form.<nom>.channel` | ID de salon Discord | Destination des réponses au formulaire |
| `ai.provider` | `openai`, `gemini`, `mistral` | Fournisseur IA du serveur |
| `ai.api_key` | secret | Clé API du fournisseur, masquée des listes |
| `ai.model` | texte | Modèle IA sélectionné |
| `music.queue.*` | géré par `/music` | File musicale persistante par serveur |
| `rss_subscriptions` | table interne | Contient aussi les abonnements YouTube via flux officiel |
| `twitch_subscriptions` | table interne | Chaînes Twitch suivies avec salon et dernier état live |
| `_system.integration.twitch.client_id` | secret système | Client ID Twitch Helix |
| `_system.integration.twitch.app_token` | secret système | App token Twitch Helix |
| `verification.code` | code privé | Code attendu par `/verify` (ne jamais le communiquer publiquement) |
| `verification.role_id` | ID de rôle | Rôle attribué après vérification |
| `verification.unverified_role_id` | ID de rôle, facultatif | Rôle retiré après vérification |

La commande `/verify` limite les tentatives à 5 par membre sur 10 minutes et journalise uniquement l’essai, jamais le code fourni.

## Activation des modules

Chaque module peut être coupé par serveur avec `/config module.<module>.enabled false`. Les modules disponibles sont `moderation`, `community`, `fun`, `voice`, `stats`, `economy`, `ai`, `integrations` et `security`. Le réglage s’applique aux commandes et aux événements Gateway correspondants (automod, anti-spam, XP, accueil/départ, vocal et notifications). Toute valeur autre que `false`, `0` ou `off` laisse le module actif ; par défaut, tous sont actifs. `/help`, la santé du bot et les commandes d’administration restent accessibles pour permettre de réactiver un module.

La protection des comptes récents utilise `security.recent_account_seconds` (âge minimal du compte en secondes, `0` pour désactiver) et `security.recent_account_action` (`passive` par défaut ou `kick`). Les détections et actions sont auditées.

L’XP peut être multipliée avec `xp.multiplier` (de 1 à 10), limitée par membre avec `xp.cooldown_seconds`, désactivée dans un salon avec `xp.exclude.channel.<channel_id> true` ou pour un rôle avec `xp.exclude.role.<role_id> true`. Les messages concernés ne donnent alors aucun XP.

`security.nuke_threshold` active le mode urgence après ce nombre de suppressions de salons/rôles ou de bans du même type en 60 secondes. Le bot conserve l’audit, passe le serveur en `maintenance` et prévient le salon de sécurité configuré. La restauration automatique des objets Discord supprimés n’est pas activée.

La vérification peut attribuer `verification.unverified_role_id` à chaque nouvel arrivant. Avec `verification.timeout_seconds` supérieur à zéro, les arrivants sont suivis en base et l’action `verification.timeout_action` (`kick` par défaut, ou `passive`) est appliquée à l’expiration s’ils n’ont pas utilisé `/verify`.

`community.suggestions_anonymous true` anonymise l’auteur des suggestions dans les logs et notifications communautaires. Le numéro de suggestion reste disponible pour permettre au staff de la traiter.

Dans un ticket, le staff autorisé par `ticket_close` peut utiliser `/ticket_transcript` pour afficher une transcription limitée aux 100 derniers messages et à la taille maximale d’une réponse Discord. Cette transcription est volontairement éphémère côté stockage : aucune archive de messages n’est conservée par le bot.

La priorité d’un ticket se règle avec `/ticket_priority basse|normale|haute|urgente` et est conservée sous `ticket.priority.<channel_id>`.

`/modules` affiche l’état courant des neuf modules sans révéler les autres valeurs de configuration.

Les clés contenant `token`, `secret`, `password`, `private`, `credential`, `api_key` ou `webhook` sont interdites. Les clés système de migration sont également réservées au code.

## ACL persistantes

1. `/groupe role modo @RoleDiscord`
2. `/permission ajouter modo ban`
3. Répéter `/groupe role` pour chaque rôle réel qui doit partager le groupe.
4. Répéter `/permission ajouter modo` pour `kick`, `mute`, `warn`, `clear`, `slowmode`, `lock`, etc.

Plusieurs groupes peuvent être liés à la même permission ; un membre est autorisé si l’un de ses rôles correspond à l’un de ces groupes. Les rôles sont les rôles Discord réels du serveur. Une modification est auditée dans SQLite.

Les modérateurs peuvent utiliser `/sanction_revoke id raison` pour annuler une sanction sans supprimer la trace d’audit. Les avertissements révoqués ne sont plus comptabilisés dans `moderation.warn_threshold`.

Un membre peut utiliser `/sanction_appeal id motif` pour déposer un appel ; celui-ci est conservé dans l’audit et envoyé au salon de logs configuré.

Les administrateurs peuvent programmer une publication avec `/announce_schedule secondes message`. Elle est persistante et sera envoyée dans le salon courant à échéance, même après un redémarrage du bot. Le staff peut utiliser `/ticket_add` et `/ticket_remove` pour gérer les participants du ticket courant.

`/role_temp membre rôle secondes` attribue un rôle Discord puis programme son retrait automatique (de 1 seconde à 30 jours). L’opération est persistante et auditée.

`/ban_temp membre secondes` utilise le stockage persistant des rappels pour débannir automatiquement le membre à échéance, y compris après redémarrage. Si la programmation échoue, le bannissement est annulé.
