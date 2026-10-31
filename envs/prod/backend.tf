terraform {
  backend "s3" {
    bucket       = "novasphere-tfstate-799395848665"
    key          = "novasphere/prod/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
