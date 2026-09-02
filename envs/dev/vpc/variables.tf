variable "aws_region" {
  type = string
}

variable "project" {
  type = string
}

variable "environment" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "single_nat_gateway" {
  type = bool
}

variable "azs" {
  type = map(object({
    public_cidr  = string
    private_cidr = string
  }))
}
