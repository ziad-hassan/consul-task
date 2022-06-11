provider "aws" {
  region = var.region
}

data "aws_availability_zones" "available" {}

locals {
  az_count = length(data.aws_availability_zones.available.names) > 3 ? 3 : length(data.aws_availability_zones.available.names)
  azs      = slice(data.aws_availability_zones.available.names, 0, local.az_count)
}

################################################################################
# VPC Module
################################################################################

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  name   = var.name
  cidr   = "10.10.0.0/16" # 65536 IPs for the vpc

  azs = local.azs
  # Max pods per node is decided by [ N * (M-1) + 2 ] N= Max ENI number per ec2 type, M= MAx prvate IPs per ENI, i.e. for t4g.2xlarge, 4 * (15-1) + 2 = 58
  private_subnets = slice(["10.10.11.0/24", "10.10.12.0/24", "10.10.13.0/24"], 0, local.az_count) # 254 IPs per subnet
  private_subnet_tags = {
    environment                         = var.environment
    "kubernetes.io/cluster/${var.name}" = "owned"
    "kubernetes.io/role/internal-elb"   = "1"
    "karpenter.sh/discovery"            = var.name
  }
  public_subnets = slice(["10.10.21.0/24", "10.10.22.0/24", "10.10.23.0/24"], 0, local.az_count)
  public_subnet_tags = {
    environment                         = var.environment
    "kubernetes.io/cluster/${var.name}" = "owned"
    "kubernetes.io/role/elb"            = "1"
  }

  enable_dns_hostnames = true
  enable_dns_support   = true

  enable_nat_gateway = true
  single_nat_gateway = true # should be at least 2 but for the sake of demo it will be 1

  enable_dhcp_options      = true
  dhcp_options_domain_name = "cluster.local"
  tags = {
    cost-key              = var.environment
  }
}