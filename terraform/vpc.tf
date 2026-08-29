# Networking for the EKS cluster.
#
# Shape: public subnets hold the ALB and the NAT gateway; worker nodes live in private
# subnets and reach the internet outbound through the NAT. The account's default VPC is
# not used because all of its subnets are public, which cannot express this layout.

data "aws_availability_zones" "available" {
  state = "available"

  # Excludes Local Zones and Wavelength Zones, which cannot host EKS subnets.
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, var.az_count)

  # Carve the /16 into /20s: the first az_count blocks are public, the next az_count are
  # private. A /20 gives ~4090 usable addresses per subnet, which matters because the VPC
  # CNI assigns every pod a real subnet IP — small subnets run out of pod IPs, not nodes.
  subnet_newbits  = 4
  public_subnets  = [for i in range(var.az_count) : cidrsubnet(var.vpc_cidr, local.subnet_newbits, i)]
  private_subnets = [for i in range(var.az_count) : cidrsubnet(var.vpc_cidr, local.subnet_newbits, i + var.az_count)]
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.0"

  name = "${var.project_name}-vpc"
  cidr = var.vpc_cidr

  azs             = local.azs
  public_subnets  = local.public_subnets
  private_subnets = local.private_subnets

  # One NAT gateway shared across AZs rather than one per AZ. Cheaper, and the loss of
  # AZ-independent egress does not matter for a learning cluster.
  enable_nat_gateway = true
  single_nat_gateway = true

  # EKS requires DNS hostnames for private endpoint resolution.
  enable_dns_hostnames = true
  enable_dns_support   = true

  # The AWS Load Balancer Controller discovers subnets by these tags. Without them it
  # fails with "unable to discover subnets" when an Ingress is created.
  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }
}
