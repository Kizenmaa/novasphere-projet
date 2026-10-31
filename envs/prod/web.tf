resource "aws_security_group" "alb" {
  name        = "novasphere-${var.environment}-alb"
  description = "HTTP public vers ALB NovaSphere"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "HTTP public du socle"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Sorties du load balancer"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "web" {
  #checkov:skip=CKV_AWS_91:Logs d acces ALB hors perimetre du module (voir SECURITE.md)
  name                       = "novasphere-${var.environment}"
  load_balancer_type         = "application"
  drop_invalid_header_fields = true
  subnets                    = module.vpc.public_subnets
  security_groups            = [aws_security_group.alb.id]
}

resource "aws_lb_target_group" "web" {
  name     = "novasphere-${var.environment}-web"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id

  health_check {
    path    = "/"
    matcher = "200"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.web.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

module "web" {
  source = "git::https://github.com/Kizenmaa/terraform-aws-novasphere-web.git?ref=v1.0.0"

  environment           = var.environment
  vpc_id                = module.vpc.vpc_id
  subnet_ids            = module.vpc.public_subnets
  alb_security_group_id = aws_security_group.alb.id
  target_group_arn      = aws_lb_target_group.web.arn
  ami_id                = data.aws_ami.debian.id
  instance_type         = var.instance_type
  instance_profile_name = aws_iam_instance_profile.web.name
  user_data = templatefile("${path.module}/../../templates/bootstrap.sh.tftpl", {
    environment = var.environment
    aws_region  = var.aws_region
  })

  # Le secret et ses droits doivent exister avant le lancement des instances (S5).
  depends_on = [aws_ssm_parameter.db_password, aws_iam_role_policy.read_secrets]
}
