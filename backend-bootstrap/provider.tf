terraform {
  required_version = ">= 1.16.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # NOTE: intentionally NO backend block here.
  # This state stores itself locally — it creates the S3/DynamoDB
  # that everything else will use as backend.
}

provider "aws" {
  region = var.aws_region
}
