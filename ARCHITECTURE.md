# Architecture Noliae Discord

Le bot est organisé en trois couches :

```text
core
 ├── contexte, erreurs, permissions, limites, événements
 ├── routeur de commandes
 └── contrats des modules

modules
 ├── moderation
 ├── tickets
 ├── community
 ├── economy
 ├── fun
 ├── stats
 ├── utility
 ├── ai
 ├── integrations
 └── voice

infrastructure
 ├── discord REST/Gateway/Interactions
 ├── SQLite, migrations, cache et sauvegardes
 └── HTTP/TLS, fournisseurs externes et observabilité
```

## Règles

- Un module ne lit jamais directement l’environnement pour sa configuration.
- Les réglages serveur sont stockés dans SQLite et modifiables depuis Discord.
- Les modules dépendent du `core`, jamais d’un autre module métier.
- Discord REST, Gateway et la base sont des adaptateurs d’infrastructure.
- Le routeur applique les contrôles communs avant de déléguer au module.
- Chaque fonctionnalité externe possède un adaptateur, une politique de sécurité et des tests.
- Les secrets sont masqués dans les listes et exports de configuration.

## Contrat d’un module

Chaque module doit fournir :

1. son identifiant (`moderation`, `tickets`, etc.) ;
2. la liste de ses commandes ;
3. son handler de commande ;
4. ses handlers d’événements ;
5. ses migrations SQLite ;
6. ses tests unitaires et d’intégration ;
7. sa documentation de configuration.

La migration depuis `commands.nol` se fait domaine par domaine. Aucun ancien handler
ne doit être supprimé avant que son équivalent modulaire soit compilé et testé.
