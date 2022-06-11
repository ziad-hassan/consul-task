# Shared Variables
variable "name" {
  type = string
}

variable "environment" {
  type = string
}

variable "region" {
  type = string
}

# EKS Variables:
variable "cluster_version" {
  type = string
}

variable "create_eks" {
  type = bool
}

variable "instance_types" {
  type = list(string)
}

variable "users" {
  type = list(any)
}



# # VPC Varibales
# variable "vpc-tags" {
#   type = map(string)
# }