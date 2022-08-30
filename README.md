# Tamr Networking Module
Tamr’s AWS resources need to be launched into an existing Virtual Private Cloud (VPC) setup that meets certain requirements. The reference network architecture here described is designed to support the Tamr AWS scale-out deployment following security best practices.

## Description
The Tamr VPC spans two Availability Zones (AZs) and includes the following resources by default:
- Load balancing Subnets (2): hosts the Application Load Balancer.
- Application subnet (1): hosts the EC2 Instance where the Tamr application is deployed (also known as Tamr VM).
- Compute subnet (1): hosts the Amazon EMR clusters and is launched in the same AZ as the Application subnet.
- Data subnets (2): used for deploying a Multi-AZ PostgreSQL Relational Database Service (RDS) instance and a Multi-AZ Amazon ElasticSearch (ES) Service domain.
- S3 Gateway VPC Endpoint: provides a secure, reliable connection to Amazon S3 without requiring an Internet gateway or NAT device.
- Network ACLs: grants access to subnets to only the resources they need and acts as another layer of security for the VPC.

## Examples
### Basic
Includes the most basic VPC that can support a Tamr deployment.
### Complete
Includes a VPC with all the variables configured.

### Public facing
Includes the following resources:
- Application load_balancer
- load_balancing subnets (2)
- NAT gateway
- HTTPS
- The Tamr-VM with a sample website for validation.

- [ALB With SSL](./examples/ssl-alb)
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
| application\_subnet\_cidr\_block | The application subnet's CIDR range | `string` | n/a | yes |
| availability\_zones | The list of availability zones where we should deploy resources | `list(string)` | n/a | yes |
| compute\_subnet\_cidr\_block | The data subnet CIDR range | `string` | n/a | yes |
| data\_subnet\_cidr\_blocks | The data subnet's CIDR range | `list(string)` | n/a | yes |
| interface\_endpoint\_ingress\_sg | Application Security group ID to associate with the interface endpoint as allowed ingress traffic. | `string` | n/a | yes |
| name\_prefix | A prefix to add to the names of all created resources. | `string` | n/a | yes |
| vpc\_cidr\_block | The cidr range for the vpc | `string` | n/a | yes |
| create\_load\_balancing\_subnets | Enable the creation of load balancing subnets for deploying a load balancer | `bool` | `true` | no |
| create\_public\_subnets | Enable the creation of public subnets for internet facing resources | `bool` | `false` | no |
| enable\_nat\_gateway | Enable the creation of a NAT gateway | `bool` | `false` | no |
| ingress\_cidr\_blocks | The cidr range that will be accessing the tamr vm. | `list(string)` | <pre>[<br>  "0.0.0.0/0"<br>]</pre> | no |
| load\_balancing\_subnets\_cidr\_blocks | The load\_balancing subnets' CIDR range | `list(string)` | <pre>[<br>  "0.0.0.0/0",<br>  "0.0.0.0/0"<br>]</pre> | no |
| public\_subnets\_cidr\_blocks | The public subnets' CIDR range | `list(string)` | <pre>[<br>  "0.0.0.0/0",<br>  "0.0.0.0/0"<br>]</pre> | no |
| tags | A map of tags to add to all resources. | `map(string)` | `{}` | no |
| tamr\_unify\_port | Identifies the default access HTTP port | `string` | `"9100"` | no |

## Outputs

| Name | Description |
|------|-------------|
| application\_subnet\_cidr\_block | The CIDR block of the Application Subnet. |
| application\_subnet\_id | ID of the subnet where mainly the Tamr VM and the Cloudwatch VPC Endpoint will be created. If `abac_valid_tags` key values are set, this subnet is required to have a valid key value tag as well. |
| compute\_subnet\_id | ID of the subnet where mainly the EMR cluster will be created. If `abac_valid_tags` key values are set, this subnet is required to have a valid key value tag as well. |
| data\_subnet\_ids | ID of the subnet where mainly the RDS will be created. If `abac_valid_tags` key values are set, this subnet is required to have a valid key value tag as well. |
| load\_balancing\_subnet\_ids | ID of the Application Load Balancer subnet. |
| public\_subnet\_ids | ID of the public subnets created in the VPC. |
| tamr\_ec2\_availability\_zone | The list of availability zones where we should deploy resources. |
| vpc\_cidr\_block | The CIDR block of the VPC. |
| vpc\_id | VPC ID of the network. |
| vpce\_logs\_endpoint\_dnsname | Cloudwatch VPC Interface Endpoint DNS name which will be provided to the script to install and configure the Cloudwatch agent. |

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
