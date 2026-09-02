terraform {
  backend "s3" {
    bucket         = "nr-k8s-eks-tfstate-ap-south-1"
    key            = "envs/dev/vpc/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "nr-k8s-eks-tfstate-lock"
    encrypt        = true
  }
}
