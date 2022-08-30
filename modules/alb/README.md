# Tamr ALB Module
In order to access Tamr using TLS encryption, we recommend using an Application Load Balancer. This module provides the resources necessary to make the deployment easy.

## Description
This module creates the following resources:
- Load Balancer with HTTP (80) to HTTPS(443) redirection and optional host routing for DMS (See the 'Configuring DMS' section)
- Security Groups

## Configuring DMS

This module supports host based routing to access different backends depending on the DNS that is being used to access the ALB. This allows many services to be accessed through the same port.
To configure access to DMS we use the following variables:
- tamr_dms_hosts (Specifies a list of DNS names that should be routed to the tamr_dms_port)
- tamr_dms_port (Specifies what port DMS is configured to use)

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| terraform | >= 0.13 |
| aws | >= 3.36, !=4.0.0, !=4.1.0, !=4.2.0, !=4.3.0, !=4.4.0, !=4.5.0, !=4.6.0, !=4.7.0, !=4.8.0 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 3.36, !=4.0.0, !=4.1.0, !=4.2.0, !=4.3.0, !=4.4.0, !=4.5.0, !=4.6.0, !=4.7.0, !=4.8.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| ec2\_instance\_id | The Tamr VM instance id | `string` | n/a | yes |
| subnet\_ids | The ids of the subnets where we will deploy the load balancer | `list(string)` | n/a | yes |
| tls\_certificate\_arn | The tls certificate ARN | `string` | n/a | yes |
| vpc\_id | The id of the VPC where we will deploy the load balancer | `string` | n/a | yes |
| enable\_host\_routing | Enabled the proxying for adding https to configurable host headers, ports and multiple instances | `bool` | `false` | no |
| host\_routing\_map | Map with hosts that should be used for routing | <pre>map(object({<br>    length       = number<br>    instance_ids = list(string)<br>    hosts        = list(string)<br>    port         = number<br>  }))</pre> | <pre>{<br>  "tamr": {<br>    "hosts": [<br>      "tamr.*.*"<br>    ],<br>    "instance_ids": [<br>      "i-000000"<br>    ],<br>    "length": 1,<br>    "port": 9100<br>  }<br>}</pre> | no |
| ingress\_cidr\_blocks | The cidr range that will be accessing the load\_balancer | `list(string)` | <pre>[<br>  "0.0.0.0/0"<br>]</pre> | no |
| tags | A map of tags to add to all resources. | `map(string)` | `{}` | no |
| tamr\_unify\_port | Identifies the default access HTTP port | `string` | `"9100"` | no |

## Outputs

| Name | Description |
|------|-------------|
| lb\_security\_group\_id | Security group ID of the loadbalancer |
| load\_balancer | Load balancer object |
| target\_group\_attachments | Target group attachments to connect target groups with instances |
| target\_groups | Target groups used for each service |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

# Development
## Generating Docs
Run `make terraform/docs` to generate the section of docs around terraform inputs, outputs and requirements.

## Checkstyles
Run `make lint`, this will run terraform fmt, in addition to a few other checks to detect whitespace issues.
NOTE: this requires having docker working on the machine running the test

## Releasing new versions
* Update version contained in `VERSION`
* Document changes in `CHANGELOG.md`
* Create a tag in github for the commit associated with the version

# License
Apache 2 Licensed. See LICENSE for full details.
