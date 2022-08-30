# TLS ALB Example
The following example will deploy the necessary resources to access Tamr and other services using HTTPS and host-based routing

# Description
This example deploys the following resources:
- VPC
- NAT Gateway
- Tamr VM instance with nginx for validation purposes.
- Application load_balancer
- EMR Cluster

In this example we will be creating a VPC with an interface VPC endpoint to allow the application subnet to communicate to the EMR API without traversing the internet without the use of InternetGateway nor a NatGateway.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| terraform | >= 0.13.1 |
| aws | >= 3.36, !=4.0.0, !=4.1.0, !=4.2.0, !=4.3.0, !=4.4.0, !=4.5.0, !=4.6.0, !=4.7.0, !=4.8.0 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 3.36, !=4.0.0, !=4.1.0, !=4.2.0, !=4.3.0, !=4.4.0, !=4.5.0, !=4.6.0, !=4.7.0, !=4.8.0 |
| template | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| availability\_zones | The list of availability zones where we should deploy resources | `list(string)` | n/a | yes |
| bucket\_name\_for\_logs | S3 bucket name for cluster logs. | `string` | n/a | yes |
| bucket\_name\_for\_root\_directory | S3 bucket name for storing root directory | `string` | n/a | yes |
| egress\_cidr\_blocks | The cidr ranges that will be accessible from EMR | `list(string)` | n/a | yes |
| ingress\_cidr\_blocks | The cidr range that will be accessing the tamr vm | `list(string)` | n/a | yes |
| key\_pair | n/a | `string` | n/a | yes |
| tls\_certificate\_arn | The tls certificate ARN | `string` | n/a | yes |
| abac\_valid\_tags | Valid tags for maintaining resources when using ABAC IAM Policies with Tag Conditions. Make sure `tags` contain a key value specified here. | `map(list(string))` | `{}` | no |
| ami\_id | The AMI to use for the tamr vm | `string` | `""` | no |
| name\_prefix | n/a | `string` | `"tamr-"` | no |
| tags | A map of tags to add to all resources. | `map(string)` | <pre>{<br>  "Name": "tamr-vpc",<br>  "Terraform": "true",<br>  "application": "tamr"<br>}</pre> | no |
| tamr\_dms\_port | Identifies the DMS access HTTP port | `string` | `"9155"` | no |
| tamr\_unify\_port | Identifies the default access HTTP port | `string` | `"9100"` | no |

## Outputs

| Name | Description |
|------|-------------|
| alb\_url | n/a |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
