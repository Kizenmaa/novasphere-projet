# Exemples de la S6, a activer un a un pendant le TP (fichier documentaire, blocs commentes).

# Etape 1 : importer un bucket cree a la main, puis generer sa configuration
#   terraform plan -generate-config-out=generated.tf
# import {
#   to = aws_s3_bucket.uploads
#   id = "novasphere-uploads-<trigramme>"
# }

# Etape 2 : renommer un module sans destruction
# moved {
#   from = module.web
#   to   = module.web_dev
# }

# Etape 4 : sortir une ressource du state sans la detruire
# removed {
#   from = aws_s3_bucket.uploads
#   lifecycle {
#     destroy = false
#   }
# }
