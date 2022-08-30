locals {
  host_routing_map = {
    "tamr" = {
      length       = 1 // This field is only required because of a terraform limitation around resource counts.
      instance_ids = [module.tamr-vm.tamr_instance.ec2_instance_id]
      hosts        = ["tamr.*.*"]
      port         = var.tamr_unify_port
    }
    "dms" = {
      length       = 1
      instance_ids = [module.tamr-vm.tamr_instance.ec2_instance_id]
      hosts        = ["dms.*.*"]
      port         = var.tamr_dms_port
    }
    "hbase" = {
      length       = module.emr.master_fleet_instance_count
      instance_ids = data.aws_instances.masters.ids
      hosts        = ["hbase.*.*"]
      port         = 16010
    }
    "ganglia" = {
      length       = module.emr.master_fleet_instance_count
      instance_ids = data.aws_instances.masters.ids
      hosts        = ["ganglia.*.*"]
      port         = 80
    }
    "spark" = {
      length       = module.emr.master_fleet_instance_count
      instance_ids = data.aws_instances.masters.ids
      hosts        = ["spark.*.*"]
      port         = 18080
    }
  }
}

module "alb" {
  source              = "../../modules/alb/"
  tls_certificate_arn = var.tls_certificate_arn
  ec2_instance_id     = module.tamr-vm.tamr_instance.ec2_instance_id
  vpc_id              = module.tamr_networking.vpc_id
  subnet_ids          = module.tamr_networking.load_balancing_subnet_ids
  tags                = var.tags
  enable_host_routing = true
  host_routing_map    = local.host_routing_map
}


data "aws_instances" "masters" {
  filter {
    name   = "tag:aws:elasticmapreduce:job-flow-id"
    values = [module.emr.tamr_emr_cluster_id]
  }
  filter {
    name   = "tag:aws:elasticmapreduce:instance-group-role"
    values = ["MASTER"]
  }
}
