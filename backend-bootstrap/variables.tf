variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "ap-south-1"
}

variable "project" {
  description = "Project name, used for resource naming"
  type        = string
  default     = "K8S-EKS"
}

variable "environment" {
  description = "Environment this backend serves (shared across envs, so keep generic)"
  type        = string
  default     = "shared"
}
