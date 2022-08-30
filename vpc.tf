locals {
  // Does not include compute subnet
  private_subnets_cidrs = flatten([
    [var.application_subnet_cidr_block],
    [local.load_balancing_subnets_cidr_blocks]
  ])
  intra_subnets_cidrs                = var.data_subnet_cidr_blocks
  application_subnet                 = module.vpc.private_subnets[0]
  data_subnets                       = [module.vpc.intra_subnets[0], module.vpc.intra_subnets[1]]
  compute_subnet                     = aws_subnet.compute_subnet.id
  public_subnets                     = module.vpc.public_subnets
  load_balancing_subnets             = var.create_load_balancing_subnets ? [module.vpc.private_subnets[2], module.vpc.private_subnets[1]] : []
  load_balancing_subnets_cidr_blocks = var.create_load_balancing_subnets ? var.load_balancing_subnets_cidr_blocks : []
  public_subnets_cidrs               = var.public_subnets_cidr_blocks
  azs                                = var.availability_zones
}
#tfsec:ignore:aws-vpc-no-excessive-port-access
module "vpc" {
  source                 = "terraform-aws-modules/vpc/aws"
  version                = "3.14.2"
  name                   = "tamr-vpc"
  cidr                   = var.vpc_cidr_block
  azs                    = local.azs
  private_subnets        = local.private_subnets_cidrs
  intra_subnets          = local.intra_subnets_cidrs
  public_subnets         = var.create_public_subnets ? local.public_subnets_cidrs : []
  enable_nat_gateway     = var.enable_nat_gateway && var.create_public_subnets
  single_nat_gateway     = var.enable_nat_gateway
  one_nat_gateway_per_az = false
  enable_vpn_gateway     = false
  // if disabled, EMR throws Error waiting for EMR Cluster state to be "WAITING" or "RUNNING"
  // See https://docs.aws.amazon.com/emr/latest/ManagementGuide/emr-troubleshoot-error-vpc.html
  enable_dns_support            = true
  enable_dns_hostnames          = true
  public_dedicated_network_acl  = false
  private_dedicated_network_acl = false
  manage_default_network_acl    = false
  manage_default_route_table    = var.enable_nat_gateway
  tags                          = var.tags
}

data "aws_subnet" "application_subnet" {
  id = local.application_subnet
}

data "aws_route_table" "application_subnet_rt" {
  subnet_id = data.aws_subnet.application_subnet.id
  depends_on = [
    module.vpc
  ]
}

resource "aws_subnet" "compute_subnet" {
  vpc_id            = module.vpc.vpc_id
  cidr_block        = var.compute_subnet_cidr_block
  availability_zone = data.aws_subnet.application_subnet.availability_zone
  tags              = var.tags
}

resource "aws_route_table_association" "compute_subnet_rta" {
  subnet_id      = aws_subnet.compute_subnet.id
  route_table_id = data.aws_route_table.application_subnet_rt.id
}
