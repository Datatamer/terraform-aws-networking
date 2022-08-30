module "endpoints" {
  source  = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  version = "3.14.2"

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
      security_group_ids  = [aws_security_group.interface_endpoint.id]
      subnet_ids          = [module.vpc.private_subnets[0]]
    },
    logs = {
      service_type        = "Interface"
      service             = "logs"
      tags                = { Name = format("%s-%s", var.name_prefix, "logs-interface-endpoint") }
      private_dns_enabled = true
      security_group_ids  = [aws_security_group.logs_interface_endpoint.id]
      subnet_ids          = [module.vpc.private_subnets[0]]
    },
    kms = {
      service_type        = "Interface"
      service             = "kms"
      tags                = { Name = format("%s-%s", var.name_prefix, "kms-interface-endpoint") }
      private_dns_enabled = true
      security_group_ids  = [aws_security_group.kms_interface_endpoint.id]
      subnet_ids          = [aws_subnet.compute_subnet.id]
    }
  }
  tags = var.tags
}

resource "aws_security_group" "interface_endpoint" {
  name        = format("%s-%s", var.name_prefix, "interface-endpoint-sg")
  description = "Security Group to be attached to the EMR Endpoint interface, which allows TCP traffic to the EMR service."
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "EMR API"
    from_port       = 443
    to_port         = 443
    protocol        = "TCP"
    security_groups = [var.interface_endpoint_ingress_sg]
  }
  tags = var.tags
}

resource "aws_security_group" "logs_interface_endpoint" {
  name        = format("%s-%s", var.name_prefix, "logs-interface-endpoint-sg")
  description = "Security Group to be attached to the Cloudwatch Endpoint interface, which allows TCP traffic to the Cloudwatch service."
  vpc_id      = module.vpc.vpc_id
  ingress {
    description = "Cloudwatch API"
    from_port   = 443
    to_port     = 443
    protocol    = "TCP"
    cidr_blocks = concat([var.compute_subnet_cidr_block, var.application_subnet_cidr_block], var.data_subnet_cidr_blocks)
  }
  tags = var.tags
}

# Creates KMS VPC Endpoint Security Group
resource "aws_security_group" "kms_interface_endpoint" {
  name        = format("%s-%s", var.name_prefix, "kms-interface-endpoint-sg")
  description = "Security Group to be attached to the KMS Endpoint interface, which allows TCP traffic to the KMS service."
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "KMS API"
    from_port   = 443
    to_port     = 443
    protocol    = "TCP"
    cidr_blocks = concat([var.compute_subnet_cidr_block, var.application_subnet_cidr_block], var.data_subnet_cidr_blocks)
  }
  tags = var.tags
}
