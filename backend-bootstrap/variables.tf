variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "ap-south-1"
}

variable "project" {
  description = "Project name, used for resource naming"
  type        = string
  default     = "k8s-eks"
}

variable "environment" {
  description = "Environment this backend serves (shared across envs, so keep generic)"
  type        = string
  default     = "shared"
}

variable "force_destroy_state_bucket" {
  description = "DANGER: allows bucket deletion even with objects/versions inside. Only true for personal dev/learning accounts, NEVER true for real prod backends."
  type        = bool
  default     = false
}
