data "aws_instance" "tamr-vm" {
  instance_id = var.ec2_instance_id
}

locals {
  counter = sum(local.counter_lengths)
  counter_lengths = tolist([for service, data in var.host_routing_map :
    data.length
  ])

  #This is the way to do it, but its not working due to terraform limitation

  # Since for_each loops dont accept lists of objects, we convert to map using index as key
  target_group_map = { for index, value in
    # The lists will be nested, so we use flatten to leave just one level
    flatten(
      #For each target group created
      [for tg in aws_lb_target_group.target_groups : [
        #For each name in the target group, we look it up in the host_routing_map and get the instance list
        for id in lookup(var.host_routing_map, tg.name).instance_ids : {
          arn      = tg.arn
          instance = id
          port     = lookup(var.host_routing_map, tg.name).port
        }
  ]]) : index => value }
}

resource "aws_lb" "alb" {
  name               = "tamr-networking-complete-example"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [module.sg_https_lb.security_group_id]
  subnets            = var.subnet_ids
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.tls_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.default_target_group.arn
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

}

/*
The default target group will be tamr
*/
resource "aws_lb_target_group" "default_target_group" {
  name = "tamr-default"
  port = var.tamr_unify_port
  health_check {
    // We accept anything that indicates that the host is running. For future implementations
    // we might add a field to the object to allow this to be configured.
    enabled  = true
    protocol = "HTTP"
    matcher  = "200-499"
  }
  protocol = "HTTP"
  vpc_id   = var.vpc_id
}

/*
The default target group attachment is the tamr-vm
*/
resource "aws_lb_target_group_attachment" "default_tamr" {
  target_group_arn = aws_lb_target_group.default_target_group.arn
  target_id        = var.ec2_instance_id
  port             = var.tamr_unify_port
}

/*
Generates a target_group for each key in the host_routing_variable
*/
resource "aws_lb_target_group" "target_groups" {
  for_each = var.enable_host_routing ? var.host_routing_map : {}
  name     = each.key
  port     = each.value.port
  health_check {
    // We accept anything that indicates that the host is running. For future implementations
    // we might add a field to the object to allow this to be configured.
    enabled  = true
    protocol = "HTTP"
    matcher  = "200-499"
  }
  protocol = "HTTP"
  vpc_id   = var.vpc_id
}

/*
When terraform makes for_each loops more flexible, the following implementation will be better.

#Generates a target_group_attachment for each element in the target_group_map

resource "aws_lb_target_group_attachment" "tg_attachments" {
  for_each         = var.enable_host_routing ? local.target_group_map : {}
  target_group_arn = each.value.arn
  target_id        = each.value.instance
  port             = each.value.port
}
*/

/*
Length Implementation to work around terraform limiting the above one.
*/
resource "aws_lb_target_group_attachment" "tg_attachments" {
  count            = local.counter
  target_group_arn = lookup(local.target_group_map, count.index).arn
  target_id        = lookup(local.target_group_map, count.index).instance
  port             = lookup(local.target_group_map, count.index).port
}

resource "aws_lb_listener_rule" "listener_rules" {
  for_each     = aws_lb_target_group.target_groups
  listener_arn = aws_lb_listener.https.arn
  action {
    type             = "forward"
    target_group_arn = each.value.arn
  }
  condition {
    host_header {
      values = lookup(var.host_routing_map, each.key).hosts
    }
  }
}

module "sg_https_lb" {
  source              = "terraform-aws-modules/security-group/aws//modules/https-443"
  version             = "4.13.0"
  name                = "web"
  use_name_prefix     = true
  description         = "Security group for tamr-vm with HTTPS ports open within VPC"
  vpc_id              = var.vpc_id
  ingress_cidr_blocks = var.ingress_cidr_blocks
  ingress_rules       = var.tls_certificate_arn == "" ? ["http-80-tcp"] : ["https-443-tcp"]
  egress_with_source_security_group_id = [
    {
      from_port                = var.tamr_unify_port
      to_port                  = var.tamr_unify_port
      protocol                 = "tcp"
      description              = "Web from the load balancer"
      source_security_group_id = tolist(data.aws_instance.tamr-vm.vpc_security_group_ids)[0]
    }
  ]
  tags = var.tags
}
