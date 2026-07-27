# Données traitées par Noliae Discord

Le bot ne doit stocker que les données nécessaires aux fonctions activées par un serveur : identifiants Discord, configuration du serveur, historique des actions de modération et statistiques demandées par les administrateurs.

Les tokens et clés d’API sont fournis uniquement par variables d’environnement et ne doivent jamais être écrits dans les logs. Les administrateurs doivent limiter les accès au fichier SQLite et effectuer des sauvegardes protégées.

La commande `/data_delete` permet de demander l’effacement des entrées d’audit, du score XP, des données d’économie, des votes musicaux, des données vocales et des rappels planifiés liés à l’utilisateur dans le serveur courant, sous réserve des obligations de conservation liées à la modération. Le code de vérification du serveur est une configuration d’administration, jamais une donnée personnelle exportée.

Lorsque `NOLIAE_AI_URL` est configuré, le contenu envoyé à `/ai` est transmis au fournisseur HTTPS choisi par l’administrateur. Les questions et réponses ne sont pas stockées par Noliae ; le fournisseur peut appliquer sa propre politique de conservation, qui doit être vérifiée avant activation. La commande est désactivée sans endpoint et clé configurés.

Lorsque `NOLIAE_TRANSLATE_URL` est configuré, le texte de `/translate` est transmis au fournisseur de traduction choisi par l’administrateur. Noliae ne le conserve pas ; la politique de conservation du fournisseur doit être vérifiée avant activation.

Le contenu de `/qr` est placé dans l’URL du service QR tiers `api.qrserver.com` afin de générer l’image. Noliae ne le stocke pas ; n’utilisez pas cette commande pour des données confidentielles.

`/define` transmet ponctuellement le mot demandé à Dictionary API pour obtenir une définition en anglais. Le mot n’est pas conservé par Noliae.

Si `automod.duplicates` est activé, le dernier message court de chaque utilisateur est conservé en SQLite uniquement pour comparer le message suivant et détecter un doublon.

Les notes de modération sont stockées par serveur dans SQLite et leur consultation est réservée aux membres autorisés par l’ACL `note`.
