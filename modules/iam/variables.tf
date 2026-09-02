variable "project" {
  type = string
}

variable "environment" {
  type = string
}

variable "kms_key_arn" {
  description = "KMS key ARN the cluster role needs for secrets encryption"
  type        = string
}
