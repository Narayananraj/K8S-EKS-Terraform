provider "aws" {
  region = var.aws_region
}

module "kms" {
  source = "../../../modules/kms"

  project     = var.project
  environment = var.environment
}
