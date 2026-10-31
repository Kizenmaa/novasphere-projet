# sécurité

Les secrets dev et prod sont dans GitHub sous DB_PASSWORD_DEV et DB_PASSWORD_PROD. La ci les donne à terraform avec TF_VAR_db_password.
Dans terraform la variable est sensitive et ephemeral. Le paramètre ssm est un SecureString écrit avec value_wo. Sa valeur n'est donc pas enregistrée dans le plan ou le state.

value_wo_version vaut 1. Pour changer le secret il faut augmenter ce nombre car terraform ne peut pas comparer une valeur qu'il ne garde pas.

Au démarrage l'instance lit le secret et l'écrit dans /etc/novasphere/app.conf avec les droits 0640. Il n'est pas affiché dans la page ni dans le script user_data.

Les rôles web ont seulement ssm:GetParameter sur le chemin de leur environnement : /novasphere/dev/* ou /novasphere/prod/*. C'est la politique prévue dans secrets.tf. On utilise un compte aws classique donc terraform crée les rôles et les profils iam.

Pour la ci oidc remplace les clés aws permanentes. La confiance est limitée au dépôt à main aux PR ou à l'environnement concerné selon le rôle.
GitHub demande maintenant les IDs dans le sub pour les nouveaux dépôts. Notre préfixe est repo:Kizenmaa@128736823/novasphere-projet@1407407636.
La documentation est ici : https://docs.github.com/en/actions/reference/security/oidc#immutable-subject-claims

Les droits ci sont dans policies/novasphere-deploy.json. Ils sont limités à us-east-1 pour le réseau aux rôles novasphere au chemin ssm novasphere et aux deux states s3.
Il reste des limites : les droits réseau sont larges dans la région le rôle ci dev peut aussi gérer prod et les rôles ci peuvent modifier leurs politiques. On n'utilise pas AdministratorAccess.
Prod attend l'approbation de Kizenmaa mais l'auto-approbation est possible. L'approbation ne vient donc pas d'une deuxième personne.

Les instances n'ont pas de port ssh ouvert. Leur http n'est accessible que depuis le sg de l'alb. Le launch template impose imdsv2 avec http_tokens = required.
Le bucket du state est chiffré en AES256 versionné verrouillé et bloqué au public.

Le scan a été fait avec checkov 3.4.0 sur envs puis sur le module web v1.0.0. Les commandes sont dans le README.
Le bucket du backend a été vérifié avec aws CLI mais ne fait pas partie des ressources de ce scan.

Avant correction : 90 contrôles passent 26 échouent et 2 sont ignorés sur envs.
Après correction : 94 passent 22 échouent et 2 sont ignorés. Aucune erreur de lecture du terraform.
Pour le module web : 11 passent 2 échouent aucun ignoré.

Les alertes du scan et ce qu'on en a fait :

- CKV_AWS_23 : descriptions ajoutées au sg alb et à ses règles. Il manque encore une description de sortie dans le module web v1.0.0.
- CKV_AWS_131 : drop_invalid_header_fields = true ajouté sur les deux alb pour rejeter les en-têtes http invalides.
- CKV_TF_1 : checkov préfère un SHA. On garde le tag v1.0.0 du module d'équipe et la version 6.7.3 du vpc comme demandé dans le sujet.
- CKV_AWS_337 : on utilise la clé kms gérée par aws pour SecureString sans créer de clé client. Le secret reste chiffré.
- CKV_AWS_382 : les sorties Internet restent ouvertes comme dans le corrigé. Les instances doivent installer les paquets et joindre parameter store. Les sorties de l'alb sont aussi larges c'est une limite du projet.
- CKV_AWS_260 : le port 80 public est sur l'alb pour pouvoir ouvrir la page. Il n'est pas public sur les instances.
- CKV_AWS_150 : la protection contre la suppression de l'alb reste désactivée pour pouvoir détruire les ressources après les sessions.
- CKV_AWS_2 CKV_AWS_103 CKV_AWS_378 et CKV2_AWS_20 : alertes liées à http et à l'absence de https. On n'a pas choisi ce bonus.
- CKV2_AWS_28 : pas de waf ce service ne fait pas partie du socle.
- CKV_AWS_91 : les logs d'accès alb sont désactivés. L'exclusion du corrigé est conservée avec sa justification.

Vérifications : aucun des deux secrets retrouvé dans les states dev/prod les user_data ou l'historique git en local. chaque environnement avait deux instances healthy.

On n'a pas vérifié tous les journaux aws et ci. Les workflows n'affichent pas le secret et GitHub masque les secrets injectés. On n'a pas testé depuis une session dans une instance dev le refus de lire le secret prod ; la restriction est bien déclarée dans le rôle web.

Pour retrouver les tests :
- PR avec les plans : https://github.com/Kizenmaa/novasphere-projet/pull/1
- Déploiement : https://github.com/Kizenmaa/novasphere-projet/actions/runs/41208709757
- Dérive : https://github.com/Kizenmaa/novasphere-projet/actions/runs/41209472283
