locals {
  application_subnet            = module.vpc.private_subnets[0]
  application_subnet_cidr_block = module.vpc.private_subnets_cidr_blocks[0]
  data_subnets                  = [module.vpc.private_subnets[2], module.vpc.private_subnets[3]]
  data_subnets_cidr_blocks      = [module.vpc.private_subnets_cidr_blocks[2], module.vpc.private_subnets_cidr_blocks[3]]
  compute_subnet                = module.vpc.private_subnets[1]
  compute_subnet_cidr_block     = module.vpc.private_subnets_cidr_blocks[1]
  public_subnets                = module.vpc.public_subnets
  public_subnets_cidr_blocks    = module.vpc.public_subnets_cidr_blocks
  load_balancing_subnets        = var.create_load_balancing_subnets ? [module.vpc.private_subnets[4], module.vpc.private_subnets[5]] : []
}

resource "aws_network_acl" "application_subnet" {
  vpc_id     = module.vpc.vpc_id
  subnet_ids = [local.application_subnet]
  tags       = var.tags

  // allow vpc traffic
  egress {
    protocol   = "-1"
    rule_no    = "100"
    action     = "allow"
    cidr_block = module.vpc.vpc_cidr_block
    from_port  = 0
    to_port    = 0
  }
  ingress {
    protocol   = "-1"
    rule_no    = "101"
    action     = "allow"
    cidr_block = module.vpc.vpc_cidr_block
    from_port  = 0
    to_port    = 0
  }
  // allow internet traffic if nat gateway is enabled
  dynamic "egress" {
    for_each = var.enable_nat_gateway ? [module.vpc.public_subnets_cidr_blocks[0]] : []
    content {
      protocol   = "tcp"
      rule_no    = "200"
      action     = "allow"
      cidr_block = "0.0.0.0/0"
      from_port  = 80
      to_port    = 80
    }
  }
  dynamic "egress" {
    for_each = var.enable_nat_gateway ? [module.vpc.public_subnets_cidr_blocks[0]] : []
    content {
      protocol   = "tcp"
      rule_no    = "201"
      action     = "allow"
      cidr_block = "0.0.0.0/0"
      from_port  = 443
      to_port    = 443
    }
  }
  dynamic "ingress" {
    for_each = var.enable_nat_gateway ? [module.vpc.public_subnets_cidr_blocks[0]] : []
    content {
      protocol   = "tcp"
      rule_no    = "202"
      action     = "allow"
      cidr_block = "0.0.0.0/0"
      from_port  = 1024
      to_port    = 65535
    }
  }

  // allow traffic from ingress_cidr_blocks if public subnets are not enabled
  dynamic "egress" {
    for_each = var.create_public_subnets ? [] : var.ingress_cidr_blocks
    content {
      protocol   = "tcp"
      rule_no    = "30${index(var.ingress_cidr_blocks, egress.value)}"
      action     = "allow"
      cidr_block = egress.value
      from_port  = 1024
      to_port    = 65535
    }
  }
  dynamic "ingress" {
    for_each = var.create_public_subnets ? [] : var.ingress_cidr_blocks
    content {
      protocol   = "tcp"
      rule_no    = "31${index(var.ingress_cidr_blocks, ingress.value)}"
      action     = "allow"
      cidr_block = ingress.value
      from_port  = 9100
      to_port    = 9100
    }
  }
  // S3 Access
  // See https://ip-ranges.amazonaws.com/ip-ranges.json for updates
  dynamic "egress" {
    for_each = data.aws_ip_ranges.s3_cidrs.cidr_blocks
    content {
      protocol   = "tcp"
      rule_no    = "40${index(data.aws_ip_ranges.s3_cidrs.cidr_blocks, egress.value)}"
      action     = "allow"
      cidr_block = egress.value
      from_port  = 443
      to_port    = 443
    }
  }
  dynamic "egress" {
    for_each = data.aws_ip_ranges.s3_cidrs.cidr_blocks
    content {
      protocol   = "tcp"
      rule_no    = "41${index(data.aws_ip_ranges.s3_cidrs.cidr_blocks, egress.value)}"
      action     = "allow"
      cidr_block = egress.value
      from_port  = 80
      to_port    = 80
    }
  }
  dynamic "ingress" {
    for_each = data.aws_ip_ranges.s3_cidrs.cidr_blocks
    content {
      protocol   = "tcp"
      rule_no    = "42${index(data.aws_ip_ranges.s3_cidrs.cidr_blocks, ingress.value)}"
      action     = "allow"
      cidr_block = ingress.value
      from_port  = 1024
      to_port    = 65535
    }
  }
}
resource "aws_network_acl" "compute_subnet" {
  vpc_id     = module.vpc.vpc_id
  subnet_ids = [local.compute_subnet]
  tags       = var.tags

  // allow vpc traffic
  egress {
    protocol   = "-1"
    rule_no    = "100"
    action     = "allow"
    cidr_block = module.vpc.vpc_cidr_block
    from_port  = 0
    to_port    = 0
  }
  ingress {
    protocol   = "-1"
    rule_no    = "101"
    action     = "allow"
    cidr_block = module.vpc.vpc_cidr_block
    from_port  = 0
    to_port    = 0
  }
  // S3 Access
  // See https://ip-ranges.amazonaws.com/ip-ranges.json for updates
  dynamic "egress" {
    for_each = data.aws_ip_ranges.s3_cidrs.cidr_blocks
    content {
      protocol   = "tcp"
      rule_no    = "20${index(data.aws_ip_ranges.s3_cidrs.cidr_blocks, egress.value)}"
      action     = "allow"
      cidr_block = egress.value
      from_port  = 443
      to_port    = 443
    }
  }
  dynamic "egress" {
    for_each = data.aws_ip_ranges.s3_cidrs.cidr_blocks
    content {
      protocol   = "tcp"
      rule_no    = "21${index(data.aws_ip_ranges.s3_cidrs.cidr_blocks, egress.value)}"
      action     = "allow"
      cidr_block = egress.value
      from_port  = 80
      to_port    = 80
    }
  }
  dynamic "ingress" {
    for_each = data.aws_ip_ranges.s3_cidrs.cidr_blocks
    content {
      protocol   = "tcp"
      rule_no    = "22${index(data.aws_ip_ranges.s3_cidrs.cidr_blocks, ingress.value)}"
      action     = "allow"
      cidr_block = ingress.value
      from_port  = 1024
      to_port    = 65535
    }
  }
  // Explicit deny when public subnets are configured
  dynamic "ingress" {
    for_each = var.create_public_subnets ? module.vpc.public_subnets_cidr_blocks : []
    content {
      protocol   = "tcp"
      rule_no    = "60${index(module.vpc.public_subnets_cidr_blocks, ingress.value)}"
      action     = "deny"
      cidr_block = ingress.value
      from_port  = 0
      to_port    = 0
    }
  }
}

resource "aws_network_acl" "data_subnets" {
  vpc_id     = module.vpc.vpc_id
  subnet_ids = local.data_subnets
  tags       = var.tags

  // allow vpc traffic
  egress {
    protocol   = "-1"
    rule_no    = "100"
    action     = "allow"
    cidr_block = module.vpc.vpc_cidr_block
    from_port  = 0
    to_port    = 0
  }
  ingress {
    protocol   = "-1"
    rule_no    = "101"
    action     = "allow"
    cidr_block = module.vpc.vpc_cidr_block
    from_port  = 0
    to_port    = 0
  }
  // Explicit deny when public subnets are configured
  dynamic "ingress" {
    for_each = var.create_public_subnets ? module.vpc.public_subnets_cidr_blocks : []
    content {
      protocol   = "tcp"
      rule_no    = "20${index(module.vpc.public_subnets_cidr_blocks, ingress.value)}"
      action     = "deny"
      cidr_block = ingress.value
      from_port  = 0
      to_port    = 65535
    }
  }
}

resource "aws_network_acl" "public_subnets" {
  vpc_id     = module.vpc.vpc_id
  subnet_ids = var.create_public_subnets ? local.public_subnets : []
  tags       = var.tags

  // Enable access to and from the ingress CIDR blocks
  dynamic "egress" {
    for_each = var.ingress_cidr_blocks
    content {
      protocol   = "-1"
      rule_no    = "10${index(var.ingress_cidr_blocks, egress.value)}"
      action     = "allow"
      cidr_block = egress.value
      from_port  = 0
      to_port    = 0
    }
  }
  dynamic "ingress" {
    for_each = var.ingress_cidr_blocks
    content {
      protocol   = "-1"
      rule_no    = "11${index(var.ingress_cidr_blocks, ingress.value)}"
      action     = "allow"
      cidr_block = ingress.value
      from_port  = 0
      to_port    = 0
    }
  }
  // Enable VPC traffic
  egress {
    protocol   = "-1"
    rule_no    = "200"
    action     = "allow"
    cidr_block = module.vpc.vpc_cidr_block
    from_port  = 0
    to_port    = 0
  }
  ingress {
    protocol   = "-1"
    rule_no    = "201"
    action     = "allow"
    cidr_block = module.vpc.vpc_cidr_block
    from_port  = 0
    to_port    = 0
  }
}

resource "aws_network_acl" "load_balancing_subnets" {
  vpc_id     = module.vpc.vpc_id
  subnet_ids = var.create_load_balancing_subnets ? local.load_balancing_subnets : []
  tags       = var.tags

  // Enable access to and from the ingress CIDR blocks
  dynamic "egress" {
    for_each = var.ingress_cidr_blocks
    content {
      protocol   = "-1"
      rule_no    = "10${index(var.ingress_cidr_blocks, egress.value)}"
      action     = "allow"
      cidr_block = egress.value
      from_port  = 0
      to_port    = 0
    }
  }
  dynamic "ingress" {
    for_each = var.ingress_cidr_blocks
    content {
      protocol   = "-1"
      rule_no    = "11${index(var.ingress_cidr_blocks, ingress.value)}"
      action     = "allow"
      cidr_block = ingress.value
      from_port  = 0
      to_port    = 0
    }
  }
  // Enable VPC traffic
  egress {
    protocol   = "-1"
    rule_no    = "200"
    action     = "allow"
    cidr_block = module.vpc.vpc_cidr_block
    from_port  = 0
    to_port    = 0
  }
  ingress {
    protocol   = "-1"
    rule_no    = "201"
    action     = "allow"
    cidr_block = module.vpc.vpc_cidr_block
    from_port  = 0
    to_port    = 0
  }
}

resource "aws_network_acl_rule" "internet_access_80" {
  egress         = true
  count          = var.enable_nat_gateway ? 1 : 0
  network_acl_id = aws_network_acl.public_subnets.id
  protocol       = "tcp"
  rule_number    = "300"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 80
  to_port        = 80
}
resource "aws_network_acl_rule" "internet_access_443" {
  egress         = true
  count          = var.enable_nat_gateway ? 1 : 0
  network_acl_id = aws_network_acl.public_subnets.id
  protocol       = "tcp"
  rule_number    = "301"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 443
  to_port        = 443
}
resource "aws_network_acl_rule" "internet_access_ephemeral" {
  egress         = false
  count          = var.enable_nat_gateway ? 1 : 0
  network_acl_id = aws_network_acl.public_subnets.id
  protocol       = "tcp"
  rule_number    = "302"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

data "aws_region" "current" {}

data "aws_ip_ranges" "s3_cidrs" {
  regions  = [data.aws_region.current.name]
  services = ["s3"]
}
