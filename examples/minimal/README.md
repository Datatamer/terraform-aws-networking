# Description

This example deploys the following resources:
- VPC
- Web Security group

In this example we creates a VPC with an interface VPC endpoint, just for the purpose if this exaple we also creates a security group to allow the proper configuration of the interface endpoint.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

No requirements.

## Providers

No provider.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| application\_subnet\_cidr\_block | The application subnet's CIDR range | `string` | n/a | yes |
| availability\_zones | The list of availability zones where we should deploy resources | `list(string)` | n/a | yes |
| compute\_subnet\_cidr\_block | The data subnet CIDR range | `string` | n/a | yes |
| data\_subnet\_cidr\_blocks | The data subnet's CIDR range | `list(string)` | n/a | yes |
| vpc\_cidr\_block | The cidr range for the vpc | `string` | n/a | yes |
| create\_load\_balancing\_subnets | Enable the creation of load balancing subnets for deploying a load balancer | `bool` | `false` | no |
| create\_public\_subnets | Enable the creation of public subnets for internet facing resources | `bool` | `false` | no |
| enable\_nat\_gateway | Enable the creation of a NAT gateway | `bool` | `false` | no |
| ingress\_cidr\_blocks | The cidr range that will be accessing the tamr vm | `list(string)` | <pre>[<br>  "0.0.0.0/0"<br>]</pre> | no |
| load\_balancing\_subnets\_cidr\_blocks | The load\_balancing subnets' CIDR range | `list(string)` | <pre>[<br>  "0.0.0.0/0",<br>  "0.0.0.0/0"<br>]</pre> | no |
| name\_prefix | n/a | `string` | `"tamr-"` | no |
| public\_subnets\_cidr\_blocks | The public subnets' CIDR range | `list(string)` | <pre>[<br>  "0.0.0.0/0",<br>  "0.0.0.0/0"<br>]</pre> | no |
| tags | A map of tags to add to all resources. | `map(string)` | <pre>{<br>  "Name": "tamr-vpc",<br>  "Terraform": "true",<br>  "application": "tamr"<br>}</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| tamr\_networking | Outputs TAMR Network information. |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
