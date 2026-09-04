variable "aws_region" {
  type    = string
  default = "ap-south-1"
}

variable "project" {
  type    = string
  default = "k8s-eks"
}

variable "github_org" {
  description = "Your GitHub username or org"
  type        = string
}

variable "github_repo" {
  description = "Repo name only, no org prefix"
  type        = string
  default     = "K8S-EKS-Terraform"
}

variable "state_bucket_arn" {
  description = "ARN of your existing tfstate bucket"
  type        = string
}

variable "lock_table_arn" {
  description = "ARN of your existing DynamoDB lock table"
  type        = string
}