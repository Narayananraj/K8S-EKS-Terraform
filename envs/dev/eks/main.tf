provider "aws" {
  region = var.aws_region
}

data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "nr-k8s-eks-tfstate-ap-south-1"
    key    = "envs/dev/vpc/terraform.tfstate"
    region = "ap-south-1"
  }
}

data "terraform_remote_state" "iam" {
  backend = "s3"
  config = {
    bucket = "nr-k8s-eks-tfstate-ap-south-1"
    key    = "envs/dev/iam/terraform.tfstate"
    region = "ap-south-1"
  }
}

data "terraform_remote_state" "kms" {
  backend = "s3"
  config = {
    bucket = "nr-k8s-eks-tfstate-ap-south-1"
    key    = "envs/dev/kms/terraform.tfstate"
    region = "ap-south-1"
  }
}

module "eks" {
  source = "../../../modules/eks"

  project      = var.project
  environment  = var.environment
  cluster_name = var.cluster_name

  cluster_role_arn = data.terraform_remote_state.iam.outputs.cluster_role_arn
  node_role_arn    = data.terraform_remote_state.iam.outputs.node_role_arn
  kms_key_arn      = data.terraform_remote_state.kms.outputs.kms_key_arn

  private_subnet_ids = data.terraform_remote_state.vpc.outputs.private_subnet_ids
  public_subnet_ids  = data.terraform_remote_state.vpc.outputs.public_subnet_ids
}
