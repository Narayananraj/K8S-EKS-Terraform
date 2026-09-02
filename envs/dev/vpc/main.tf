provider "aws" {
  region = var.aws_region
}

module "vpc" {
  source = "../../../modules/vpc"

  project            = var.project
  environment        = var.environment
  cluster_name       = var.cluster_name
  vpc_cidr           = var.vpc_cidr
  single_nat_gateway = var.single_nat_gateway
  azs                = var.azs
}
