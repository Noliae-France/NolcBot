# Matrice de couverture Noliae Discord

Cette matrice décrit l’état vérifiable du dépôt. « Livré » signifie que le code est présent et passe `./check.sh`; « adaptateur » signifie que le flux dépend d’un service ou d’un secret externe; « restant » signifie qu’il ne faut pas le présenter comme disponible.

## Livré et vérifié

| Domaine | Fonctionnalités |
| --- | --- |
| Socle | Slash commands, Gateway, reconnexion, vérification Ed25519, réponses privées, gestion d’erreurs |
| Configuration | Configuration par serveur, dashboard multi-serveurs, maintenance, préfixe, salons configurables |
| ACL | Groupes persistants liés aux vrais rôles Discord, rôles de permission injectables depuis Discord dans SQLite, permissions multiples, nettoyage des associations |
| Modération | Warn, sanctions, révocation et appels, ban temporaire, kick, ban, unban, timeout, suppression unitaire ou groupée, slowmode, verrouillage, notes, rôles temporaires |
| Sécurité | Automod, anti-spam, anti-raid, détection configurable des comptes récents, seuil anti-nuke avec mode urgence, vérification par code avec rôle non vérifié et expiration, blacklist/whitelist, limites de commandes, logs spécialisés |
| Communauté | Bienvenue/départ, auto-rôle, tickets avec participants, prise en charge, priorité et transcription récente, signalements, suggestions avec statuts et mode anonyme, sondages persistants avec vote unique et clôture, annonces immédiates et programmées, partenariats |
| Vocal | Suivi du temps vocal, rôles au seuil, salons temporaires, déplacement, registre persistant et nettoyage automatique |
| Divertissement | Jeux, quiz, morpion persistant, memes personnalisés, défis, badges, économie virtuelle, XP avec classement, réinitialisation, multiplicateur et exclusions |
| Utilitaires | Informations Discord, calcul, conversions, timestamps, fuseaux, météo, définitions, QR, mots de passe, rappels |
| Données | SQLite, migrations, sauvegardes, restauration, export CSV, export personnel et suppression personnelle |
| Statistiques | Compteurs, rapports jour/semaine/mois, rapports automatiques, export CSV, métriques Prometheus |
| Notifications | RSS, YouTube, GitHub, Reddit, Twitch Helix, calendrier ICS ponctuel et abonnements périodiques, invitations observées et alertes suspectes |
| IA | Conversation, résumé, réécriture, idées, FAQ IA, limites et désactivation par serveur |

## Dépendant d’un adaptateur externe

- IA, traduction, météo, QR et Twitch nécessitent leurs variables d’environnement et leurs fournisseurs respectifs.
- Les flux YouTube, GitHub, Reddit et RSS nécessitent un accès HTTPS sortant.
- Les notifications Discord nécessitent les permissions du bot et une hiérarchie de rôles compatible.

## Restant explicitement

- Lecture musicale vocale complète : session Voice Gateway, UDP, chiffrement RTP et encodage Opus.
- Connecteurs dédiés TikTok, X, calendriers avec synchronisation complète des occurrences, formulaires et applications tierces spécifiques.
- Interface dashboard avancée avec édition structurée de tous les modules et authentification utilisateur complète; la transcription de ticket reste limitée et non archivée.

Ces éléments restent isolés derrière des points d’extension afin de ne pas fragiliser le Gateway ou la persistance existante.
