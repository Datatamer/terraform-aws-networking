locals {
  ami_id = var.ami_id != "" ? var.ami_id : data.aws_ami.tamr-vm.id
  az     = length(var.availability_zones) > 0 ? var.availability_zones[0] : data.aws_availability_zones.available.names[0]
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "tamr-vm" {
  most_recent = true
  owners      = ["679593333241"]
  name_regex  = "ami-[a-z0-9]*-with-tamr-v202[0-9]*-[0-9]*gb-[0-9]*-no-license-.*"
  filter {
    name   = "product-code"
    values = ["832nkbrayw00cnivlh6nbbi6p"]
  }
}

data "template_file" "install_nginx" {
  template = file("${path.module}/files/install-nginx.tpl")
  vars = {
    tamr_unify_port = var.tamr_unify_port
  }
}

data "template_file" "setup_dms" {
  template = file("${path.module}/files/setup-dms.tpl")
  vars = {
    tamr_unify_port = var.tamr_unify_port
    tamr_dms_port   = var.tamr_dms_port
  }
}

module "sg_vm_web" {
  source                  = "git::git@github.com:Datatamer/terraform-aws-security-groups.git?ref=1.0.1"
  vpc_id                  = module.tamr_networking.vpc_id
  egress_cidr_blocks      = var.egress_cidr_blocks
  egress_protocol         = "all"
  ingress_security_groups = [module.alb.lb_security_group_id]
  ingress_protocol        = "tcp"
  ingress_ports           = [var.tamr_unify_port, var.tamr_dms_port]
  sg_name_prefix          = format("%s-%s", "example-complete", "tamr-vm")
}

module "tamr-vm" {
  source                      = "git::git@github.com:Datatamer/terraform-aws-tamr-vm.git?ref=5.0.0"
  aws_role_name               = format("%s-tamr-ec2-role", var.name_prefix)
  aws_instance_profile_name   = format("%s-tamr-ec2-instance-profile", var.name_prefix)
  aws_emr_creator_policy_name = format("%sEmrCreatorPolicy", var.name_prefix)
  ami                         = local.ami_id
  instance_type               = "r5.2xlarge"
  key_name                    = var.key_pair
  availability_zone           = local.az
  subnet_id                   = module.tamr_networking.application_subnet_id
  bootstrap_scripts           = [data.template_file.setup_dms.rendered, data.template_file.install_nginx.rendered]
  s3_policy_arns              = []
  depends_on = [
    module.tamr_networking
  ]

  security_group_ids = module.sg_vm_web.security_group_ids
  tags               = var.tags
}
