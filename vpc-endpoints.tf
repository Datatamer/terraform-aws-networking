module "endpoints" {
  source = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"

  vpc_id = module.vpc.vpc_id

  endpoints = {
    s3 = {
      service_type    = "Gateway"
      service         = "s3"
      tags            = { Name = format("%s-%s", var.name_prefix, "s3-vpc-endpoint") }
      route_table_ids = flatten([module.vpc.private_route_table_ids[0]])
    },
    elasticmapreduce = {
      service_type        = "Interface"
      service             = "elasticmapreduce"
      tags                = { Name = format("%s-%s", var.name_prefix, "emr-interface-endpoint") }
      private_dns_enabled = true
      security_group_ids  = module.aws-sg-interface_endpoint.security_group_ids
      subnet_ids          = [module.vpc.private_subnets[0]]
    },
  }
  tags = var.tags
}

module "aws-sg-interface_endpoint" {
  source              = "git::git@github.com:Datatamer/terraform-aws-security-groups.git?ref=1.0.0"
  vpc_id              = module.vpc.vpc_id
  ingress_cidr_blocks = [var.application_subnet_cidr_block]
  ingress_protocol    = "tcp"
  egress_protocol     = "all"
  ingress_ports       = ["443"]
  sg_name_prefix      = format("%s-%s", var.name_prefix, "interface-endpoint-sg")
  tags                = var.tags
}
