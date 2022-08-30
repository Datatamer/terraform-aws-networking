locals {
  this_application = ["Spark", "hbase", "ganglia"]
}

# Set up logs bucket with read/write permissions
module "emr-logs-bucket" {
  source      = "git::git@github.com:Datatamer/terraform-aws-s3.git?ref=1.3.2"
  bucket_name = var.bucket_name_for_logs
  read_write_actions = [
    "s3:HeadBucket",
    "s3:PutObject",
  ]
  read_write_paths = [""] # r/w policy permitting specified rw actions on entire bucket
  tags             = var.tags
}

# Set up root directory bucket
module "emr-rootdir-bucket" {
  source           = "git::git@github.com:Datatamer/terraform-aws-s3.git?ref=1.3.2"
  bucket_name      = var.bucket_name_for_root_directory
  read_write_paths = [""] # r/w policy permitting default rw actions on entire bucket
  tags             = var.tags
}

# EMR cluster
module "emr" {
  # See CA-131
  depends_on = [
    module.tamr_networking
  ]
  source = "git::git@github.com:Datatamer/terraform-aws-emr.git?ref=9.0.0"
  # Configurations
  create_static_cluster = true
  release_label         = "emr-5.29.0" # spark 2.4.4
  applications          = local.this_application
  emr_config_file_path  = "./emr-config.json"
  tags                  = var.tags
  abac_valid_tags       = var.abac_valid_tags

  # Networking
  subnet_id = module.tamr_networking.compute_subnet_id
  vpc_id    = module.tamr_networking.vpc_id

  # External resource references
  bucket_name_for_root_directory = module.emr-rootdir-bucket.bucket_name
  bucket_name_for_logs           = module.emr-logs-bucket.bucket_name
  s3_policy_arns                 = [module.emr-logs-bucket.rw_policy_arn, module.emr-rootdir-bucket.rw_policy_arn]
  bucket_path_to_logs            = "logs/spark-example-complete-cluster/"
  key_pair_name                  = var.key_pair

  # Names
  cluster_name                  = format("%s-%s", "example-complete", "-EMR-Cluster")
  emr_service_role_name         = format("%s-%s", "example-complete", "-service-role")
  emr_ec2_role_name             = format("%s-%s", "example-complete", "-ec2-role")
  emr_ec2_instance_profile_name = format("%s-%s", "example-complete", "-instance-profile")
  emr_service_iam_policy_name   = format("%s-%s", "example-complete", "-service-policy")
  master_instance_fleet_name    = format("%s-%s", "example-complete", "-MasterInstanceFleet")
  core_instance_fleet_name      = format("%s-%s", "example-complete", "-CoreInstanceFleet")

  # Scale
  master_instance_on_demand_count = 1
  core_instance_on_demand_count   = 1
  master_instance_type            = "m6g.xlarge"
  core_instance_type              = "r6g.xlarge"
  master_ebs_size                 = 50
  core_ebs_size                   = 50

  # Security Group IDs
  emr_managed_master_sg_ids = module.aws-emr-sg-master.security_group_ids
  emr_managed_core_sg_ids   = module.aws-emr-sg-core.security_group_ids
  emr_service_access_sg_ids = module.aws-emr-sg-service-access.security_group_ids
}

module "sg-ports" {
  source       = "git::https://github.com/Datatamer/terraform-aws-emr.git//modules/aws-emr-ports?ref=9.0.0"
  applications = local.this_application
}

module "aws-emr-sg-master" {
  source                  = "git::git@github.com:Datatamer/terraform-aws-security-groups.git?ref=1.0.1"
  vpc_id                  = module.tamr_networking.vpc_id
  ingress_cidr_blocks     = var.ingress_cidr_blocks
  ingress_security_groups = module.sg_vm_web.security_group_ids
  ingress_ports           = module.sg-ports.ingress_master_ports
  egress_cidr_blocks      = var.egress_cidr_blocks
  sg_name_prefix          = format("%s-%s", "example-complete", "-master")
  egress_protocol         = "all"
  ingress_protocol        = "tcp"
}

module "aws-emr-sg-core" {
  source                  = "git::git@github.com:Datatamer/terraform-aws-security-groups.git?ref=1.0.1"
  vpc_id                  = module.tamr_networking.vpc_id
  ingress_cidr_blocks     = var.ingress_cidr_blocks
  ingress_security_groups = module.sg_vm_web.security_group_ids
  ingress_ports           = module.sg-ports.ingress_core_ports
  egress_cidr_blocks      = var.egress_cidr_blocks
  sg_name_prefix          = format("%s-%s", "example-complete", "-core")
  egress_protocol         = "all"
  ingress_protocol        = "tcp"
}

module "aws-emr-sg-service-access" {
  source              = "git::git@github.com:Datatamer/terraform-aws-security-groups.git?ref=1.0.1"
  vpc_id              = module.tamr_networking.vpc_id
  ingress_cidr_blocks = var.ingress_cidr_blocks
  ingress_ports       = module.sg-ports.ingress_service_access_ports
  sg_name_prefix      = format("%s-%s", "example-complete", "-service-access")
  egress_protocol     = "all"
  ingress_protocol    = "tcp"
}
