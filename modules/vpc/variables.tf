variable "project" {
  type = string
}

variable "environment" {
  type = string
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "azs" {
  description = "Map of AZ suffix => {public_cidr, private_cidr}"
  type = map(object({
    public_cidr  = string
    private_cidr = string
  }))
}

variable "single_nat_gateway" {
  description = "Cost lever: true = 1 shared NAT (dev), false = 1 NAT per AZ (prod HA)"
  type        = bool
  default     = true
}

variable "cluster_name" {
  description = "Used to tag subnets for EKS/ALB auto-discovery"
  type        = string
}
