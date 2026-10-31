# novasphere

On est partis du dossier fin-S7 du cours. Le projet déploie la même petite page sur aws en dev et en prod. Le trigramme utilisé est alp. On a gardé le socle demandé sans bonus.

Il faut Git aws CLI v2 terraform 1.15.8 et un compte GitHub.
Tout est dans la région us-east-1 sur le compte 799395848665.

Le code est ici : https://github.com/Kizenmaa/novasphere-projet
Le module web est ici : https://github.com/Kizenmaa/terraform-aws-novasphere-web
On utilise le tag v1.0.0 du module.

## pour commencer

Le bucket novasphere-tfstate-799395848665 doit déjà exister. Si on repart de zéro il faut le créer dans s3 activer le versionnement le chiffrement AES256 et les quatre options de blocage de l'accès public.

Les deux backend.tf utilisent ce bucket avec une clé différente :
- novasphere/dev/terraform.tfstate
- novasphere/prod/terraform.tfstate

On active le verrou avec use_lockfile = true. Le bucket reste en place quand on détruit dev et prod.

Depuis le dossier novasphere-projet on se connecte à aws :

aws login --profile novasphere-dev --region us-east-1
$env:AWS_PROFILE = "novasphere-dev"
$env:AWS_REGION = "us-east-1"
aws sts get-caller-identity

Le profil correspond à l'utilisateur iam novasphere-dev. Il lui faut les droits du fichier policies/novasphere-deploy.json et l'accès au bucket du state. L'autorisation SignInLocalDevelopmentAccess permet la connexion avec aws login.

Copier terraform.tfvars.example en terraform.tfvars dans dev et dans prod puis vérifier les valeurs. Aucun mot de passe dans ces fichiers.

terraform -chdir=envs/dev init
terraform -chdir=envs/prod init
terraform -chdir=envs/dev validate
terraform -chdir=envs/prod validate

Pour donner le secret à terraform dans un terminal local :

$novaSecret = Read-Host "Secret de l'environnement" -AsSecureString
$env:TF_VAR_db_password = [System.Net.NetworkCredential]::new("", $novaSecret).Password
Remove-Variable novaSecret

Il faut garder cette variable pour le plan et l'apply. terraform ne sauvegarde pas sa valeur dans le plan.

## avec github actions

La première fois on déploie dev depuis le PC avec un plan complet. Cela crée aussi les rôles aws dont GitHub aura besoin. Les deux rôles ci sont dans le state dev même celui de prod.

Après avoir saisi le secret dev avec les commandes ci-dessus :

terraform -chdir=envs/dev plan -out=tfplan

Lire le plan avant de continuer puis appliquer le fichier sauvegardé :

terraform -chdir=envs/dev apply tfplan

Après ce premier démarrage les changements et le déploiement de prod passent par GitHub Actions. Si on a détruit complètement dev il faut refaire ce démarrage local avant de relancer la ci.

Sur GitHub dans Settings puis Secrets and variables / Actions ajouter :
- DB_PASSWORD_DEV et DB_PASSWORD_PROD dans les secrets avec une valeur différente pour chaque environnement.
- AWS_ROLE_DEV dans les variables : arn:aws:iam::799395848665:role/novasphere-ci-dev
- AWS_ROLE_PROD dans les variables : arn:aws:iam::799395848665:role/novasphere-ci-prod

Créer les environnements dev et prod dans Settings / Environments. Pour prod activer Required reviewers et ajouter Kizenmaa. Laisser Prevent self-review décoché et désactiver le contournement par les administrateurs.

On ouvre ensuite une PR vers main. Le workflow vérifie le format lance validate et met les plans dev et prod en commentaire.
Au merge dev est déployé. Pour prod il faut cliquer sur Review deployments et approuver.

Chaque déploiement crée son fichier de plan puis applique ce fichier. Le plan est recalculé sur main : ce n'est pas le fichier utilisé dans la PR.

Dans Actions / terraform Apply le bouton Run workflow sur main lance la vérification de dérive sans déployer. Elle est aussi prévue chaque jour à 03:00 UTC. Le code 0 veut dire aucun changement 2 une différence et 1 une erreur.

## pour vérifier

terraform -chdir=envs/dev output
terraform -chdir=envs/prod output

Ouvrir http://<alb_dns_name>/ dans le navigateur. On doit voir dev ou prod et le nom de l'instance. Le projet utilise HTTP, pas HTTPS.

Pour vérifier les instances derrière l'alb :

aws elbv2 describe-target-health --target-group-arn <target_group_arn>

On attend deux instances healthy par environnement. Un nouveau plan doit être vide si rien n'a changé.
La PR 1 le déploiement après merge et la vérification de dérive ont été testés. Les liens sont dans SECURITE.md.

Pour refaire le scan :

pip install checkov==3.4.0
checkov -d envs --framework terraform --download-external-modules false --skip-download --compact
checkov -d ../terraform-aws-novasphere-web --framework terraform --download-external-modules false --skip-download --compact

Le second dossier doit être cloné au tag v1.0.0. Ce scan ne télécharge pas le module vpc du registre. Les alertes restantes sont expliquées dans SECURITE.md.

## quand on a fini

Détruire prod avant dev car dev contient les rôles ci des deux environnements.
Saisir le secret prod dans TF_VAR_db_password puis lancer :

terraform -chdir=envs/prod destroy

Saisir ensuite le secret dev avec la même méthode et lancer :

terraform -chdir=envs/dev destroy
Remove-Item Env:TF_VAR_db_password

Taper yes et attendre destroy complete. Vérifier dans aws qu'il ne reste plus d'instances d'alb ou d'asg du projet. On garde le bucket s3.
Arrêter seulement les instances ne suffit pas : l'asg pourrait les remplacer.
