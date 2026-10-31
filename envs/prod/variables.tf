variable "aws_region" {
  description = "Region AWS de deploiement"
  type        = string
  default     = "us-east-1"
}

variable "owner" {
  description = "Trigramme de l'etudiant, utilise pour nommer et tagger les ressources"
  type        = string

  validation {
    condition     = can(regex("^[a-z]{3}$", var.owner))
    error_message = "Le trigramme doit etre compose de 3 lettres minuscules."
  }
}

variable "instance_type" {
  description = "Type d'instance EC2"
  type        = string
  default     = "t3.micro"
}


variable "environment" {
  description = "dev ou prod"
  type        = string

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment doit valoir dev ou prod."
  }
}
