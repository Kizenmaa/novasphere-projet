# cadrage

Projet : novasphere. Trigramme : alp.
Référent Git et aws : alp.
Dépôt : Kizenmaa/novasphere-projet.
Compte aws : 799395848665 région us-east-1.

On garde le contexte du cours qui est que novasphere est une petite application web sur aws.
La page affiche le nom du projet dev ou prod et le nom de l'instance.
Dev sert à tester avant de passer en prod.
L'alb répartit les requêtes et l'asg garde au moins deux instances.
githu actions fait le déploiement et les instances récupèrent leur secret dans parameter store.

On fait seulement le socle demandé sans bonus. On ne met donc pas de https de rds de Packer d'Ansible au démarrage de second service ni de tests de module en extension.
On garde les services de base du cours. Les ressources sont détruites après les sessions pour limiter les frais en gardant le bucket du state.

(pas fait avec le prof en cours car pas assez avancé a ce moment la)
