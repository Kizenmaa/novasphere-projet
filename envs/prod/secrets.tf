variable "db_password" {
  description = "Mot de passe applicatif, fourni par TF_VAR_db_password"
  type        = string
  ephemeral   = true
  sensitive   = true
}

resource "aws_ssm_parameter" "db_password" {
  name             = "/novasphere/${var.environment}/db_password"
  type             = "SecureString"
  value_wo         = var.db_password
  value_wo_version = 1
}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "ec2_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "web" {
  name               = "novasphere-${var.environment}-web"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json
}

resource "aws_iam_role_policy" "read_secrets" {
  name = "read-secrets"
  role = aws_iam_role.web.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["ssm:GetParameter"]
      Resource = "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/novasphere/${var.environment}/*"
    }]
  })
}

resource "aws_iam_instance_profile" "web" {
  name = "novasphere-${var.environment}-web"
  role = aws_iam_role.web.name
}
