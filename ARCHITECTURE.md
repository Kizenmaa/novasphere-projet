# architecture

Quand on ouvre la page la requête passe par là :

Navigateur (http port 80) -> alb public -> target group -> deux instances nginx dans un asg sur deux zones.


L'asg garde au moins deux instances. Le launch template indique l'image Debian 12 le type t3.micro le script de démarrage et le profil iam. C'est la base de notre installation.

Dev et prod ont chacun leur vpc leur alb et leur asg dans us-east-1a et us-east-1b.
Le réseau dev est 10.0.0.0/16 et celui de prod est 10.1.0.0/16. Les instances ont une IP publique pour installer nginx et joindre aws. Il n'y a pas de NAT Gateway.

Le sg de l'alb accepte http depuis Internet. Celui des instances accepte http seulement depuis le sg de l'alb. On n'ouvre pas ssh.

Le vpc vient du module public terraform-aws-modules/vpc/aws version 6.7.3.
Notre module web contient le sg des instances le launch template et l'asg. Dev et prod appellent le même tag v1.0.0 depuis le second dépôt Git. Il a des variables typées des validations et des outputs.

On a un dossier envs/dev et un dossier envs/prod. Chacun a ses variables et son réseau. Les deux utilisent le même module.

Le script commun fait 9 lignes. Il installe nginx récupère le secret dans parameter store avec le profil iam et crée la page avec le nom de l'environnement. imdsv2 est activé. Le secret n'est pas écrit dans le script.

Les states sont dans un bucket s3 chiffré et versionné avec une clé et un verrou par environnement.
GitHub utilise oidc pour se connecter à aws sans clé permanente. La prod attend une approbation avant son déploiement.

on a écarté le state local pour garder un état partagé dans s3. on utilise un module commun plutôt que de recopier le code dans dev et prod. aucune extension bonus n'a été ajoutée.
