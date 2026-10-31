# Fournisseur OIDC GitHub : un seul par compte AWS. Sans thumbprint_list (optionnel depuis
# le provider 5.81 ; AWS valide GitHub avec sa propre bibliotheque de CA).
resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
}

resource "aws_iam_role" "ci" {
  name = "novasphere-ci-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = aws_iam_openid_connect_provider.github.arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = { "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com" }
        StringLike = {
          "token.actions.githubusercontent.com:sub" = [
            "repo:Kizenmaa/novasphere-projet:pull_request",
            "repo:Kizenmaa/novasphere-projet:ref:refs/heads/main",
            "repo:Kizenmaa/novasphere-projet:environment:dev"
          ]
        }
      }
    }]
  })
}

# S7 : politique limitee aux services du socle et aux roles NovaSphere.
resource "aws_iam_role_policy" "ci_deploy" {
  name   = "novasphere-deploy"
  role   = aws_iam_role.ci.id
  policy = file("${path.module}/../../policies/novasphere-deploy.json")
}

output "ci_role_arn" {
  description = "A placer dans la variable de depot AWS_ROLE_DEV"
  value       = aws_iam_role.ci.arn
}

# S7 : le fournisseur GitHub est unique ; les deux roles CI sont crees dans le state dev.
resource "aws_iam_role" "ci_prod" {
  name = "novasphere-ci-prod"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = aws_iam_openid_connect_provider.github.arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = { "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com" }
        StringLike = {
          "token.actions.githubusercontent.com:sub" = [
            "repo:Kizenmaa/novasphere-projet:environment:prod",
            "repo:Kizenmaa/novasphere-projet:ref:refs/heads/main"
          ]
        }
      }
    }]
  })
}

resource "aws_iam_role_policy" "ci_prod_deploy" {
  name   = "novasphere-deploy"
  role   = aws_iam_role.ci_prod.id
  policy = file("${path.module}/../../policies/novasphere-deploy.json")
}

output "ci_prod_role_arn" {
  value = aws_iam_role.ci_prod.arn
}
