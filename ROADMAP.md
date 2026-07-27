# Noliae Discord — feuille de route

La liste fournie couvre un produit complet. Elle est découpée pour garder un bot stable à chaque étape.

## État réel au 27 juillet 2026

Livré et vérifié dans le dépôt : socle slash/Gateway avec reconnexion exponentielle, ACL persistantes par rôles Discord avec comparaison exacte, configuration par serveur, préfixe Gateway personnalisable, SQLite version 2, sauvegardes/restauration, modération avec sanctions progressives et historique détaillé, automod, anti-raid, anti-spam, tickets avec limite anti-abus, rappels créables/listables/annulables, XP/badges avec rôles par niveau, économie transactionnelle avec récompenses quotidienne/hebdomadaire, travail, boutique, achats, inventaire et historique, sondages, statistiques/CSV incluant les entrées/sorties vocales, salons vocaux temporaires avec nettoyage automatique, file musicale persistante, export CSV des logs, dashboard avec lecture de configuration non sensible et écriture authentifiée, métriques Prometheus, webhook Discord sécurisé, vérification ponctuelle de sites HTTPS publics, lecture ponctuelle et abonnement RSS jusqu’à 10 flux par serveur avec déduplication, notifications persistantes YouTube/GitHub/Reddit via leurs flux publics, statut et notifications persistantes Twitch Helix, invitations actuelles et classement des utilisations observées, workflow de partenariats avec demandes et décisions auditées, météo ponctuelle HTTPS, adaptateurs IA avec conversation, résumé, réécriture et génération d’idées, traduction OpenAI/LibreTranslate-compatibles désactivables, définitions, QR via service tiers, outils timestamp/fuseau horaire et génération de mot de passe éphémère, morpion persistant par salon, FAQ personnalisable, notes privées et bannissements temporaires persistants.

Restant explicitement : lecture/audio vocal complète, connecteurs dédiés TikTok/X, synchronisation complète des occurrences de calendriers, formulaires, transcription avancée des tickets et dashboard avec authentification utilisateur structurée. Les adaptateurs météo/traduction/QR/IA actuels restent ponctuels, limités et dépendants de fournisseurs externes.

## Phase 1 — socle fiable

- commandes slash et réponses privées ;
- aide et gestion d’erreurs ;
- ACL par rôles Discord ;
- configuration par serveur ;
- stockage persistant ;
- limitation anti-spam ;
- token uniquement via variables d’environnement ;
- logs des actions sensibles ;
- `/help`, `/ping`, `/userinfo`, `/serverinfo`.

## Phase 2 — modération et sécurité

- avertissements avec identifiant, raison et historique ;
- kick, ban, débannissement, timeout, mute ;
- suppression, verrouillage et slowmode ;
- automodération configurable ;
- anti-raid et mode urgence ;
- restauration et alertes propriétaires ; vérification par code avec limitation anti-brute-force.

## Phase 3 — communauté

- bienvenue/départ et vérification ;
- rôles automatiques, boutons et menus ;
- tickets, appels de sanctions, annonces programmées et statistiques ; la transcription complète reste à réaliser ;
- logs séparés par catégorie.

## Phase 4 — engagement

- niveaux et expérience ;
- économie virtuelle ;
- suggestions et sondages ;
- annonces, rappels et événements.

## Phase 5 — vocal

- salons vocaux temporaires ;
- statistiques vocales ;
- file musicale persistante avec boucle, mélange et vote ; lecture audio réelle uniquement avec des sources autorisées et compatibles avec les droits d’utilisation.

## Phase 6 — divertissement et utilitaires

- memes, devinettes, quiz, jeux et défis quotidiens ;
- succès, badges et mini-jeux multijoueurs ;
- avatars, bannières, rôles et salons ;
- calculatrice, conversions, traductions, météo et fuseaux horaires ;
- QR codes, rappels, timestamps Discord et outils de texte.

## Phase 7 — intégrations et IA

- YouTube, Twitch, Reddit, GitHub, RSS et webhooks ;
- notifications de publications et statuts externes ;
- API personnalisées configurables ;
- assistant, résumés, réécriture, FAQ et recherche documentaire ;
- limites d’utilisation, filtrage et protection des données.

## Phase 8 — statistiques et administration

- activité des membres, messages, salons, vocal, commandes et modération ;
- rapports quotidiens, hebdomadaires et mensuels avec export CSV ;
- suivi des invitations, partenariats et récompenses ;
- tableau de bord web, multi-serveurs, maintenance et migrations ;
- liste noire/blanche globale, statut, redémarrage sécurisé et rapports d’erreur.

## Qualité obligatoire à chaque phase

- base de données fiable, cache et sauvegardes restaurables ;
- architecture modulaire et files d’attente pour les actions massives ;
- gestion des erreurs et des limites API Discord ;
- logs techniques structurés, tests automatisés et environnement séparé ;
- fuseaux horaires, langues, confidentialité et suppression des données personnelles.

Les intégrations externes, l’IA et la musique seront isolées derrière des adaptateurs avec limites, timeouts et désactivation par serveur.

Chaque module sera activable par serveur et protégé par les ACL.
