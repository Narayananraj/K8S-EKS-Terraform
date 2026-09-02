provider "aws" {
  region = var.aws_region
}

data "terraform_remote_state" "kms" {
  backend = "s3"

  config = {
    bucket = "nr-k8s-eks-tfstate-ap-south-1"
    key    = "envs/dev/kms/terraform.tfstate"
    region = "ap-south-1"
  }
}

module "iam" {
  source = "../../../modules/iam"

  project     = var.project
  environment = var.environment
  kms_key_arn = data.terraform_remote_state.kms.outputs.kms_key_arn
}
