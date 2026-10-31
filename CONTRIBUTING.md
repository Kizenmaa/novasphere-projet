# règles de travail

trigramme utilisé : alp.

- faire les changements sur une branche feat/... ou fix/... puis ouvrir une PR vers main.
- lire les plans dev et prod avant le merge.
- ne pas envoyer les states tfvars plans clés ou fichiers .env sur GitHub.
- ne jamais mettre un secret dans le code un commit ou un log.
- pour changer le module publier un nouveau tag dans son dépôt puis changer la version appelée par dev et prod. ne pas modifier un tag déjà publié.
- ne pas lancer deux opérations sur le même state. ne pas retirer un verrou sans avoir vérifié ce qui tourne.
- appliquer le fichier de plan sauvegardé. Approuver prod avant son déploiement.
- détruire prod puis dev à la fin de la session pour éviter les frais.
- garder les dépôts accessibles au jury et poser rendu-final avant la date limite.
