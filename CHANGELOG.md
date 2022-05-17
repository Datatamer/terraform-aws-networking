# Tamr Terraform AWS Networking Repo

## v1.2.1 - May 16th 2022
* Adds `data_subnet_cidr_blocks`as allowed ingress traffic in logs endpoint security group.

## v1.2.0 - April 7th 2022
* Adds KMS VPC Interface Endpoint.

## v1.1.2 - April 5th 2022
* Forces dependency between route table datasource and vpc module.
* Adds conditional creation of Public and Load Balancing subnets nacls.

## v1.1.1 - February 7th 2022
* Adds application subnet cidr block (Tamr VM subnet cidr block) as allowed cidr block for ingress traffic in the security group for the Cloudwatch Interface Endpoint.

## v1.1.0 - January 11st 2022
* Adds Cloudwatch VPC Interface Endpoint.
* Adds Cloudwatch VPC Interface Endpoint security group.
* Adds a description to each output.

## v1.0.1 - December 30th 2021
* Forces dependency between EMR and Networking module.

## v1.0.0 - November 29th 2021
* Refactors ALB Module
* Adds EMR to complete example
* Adds Host-Based Routing
* Adds interface endpoint blocks to allow Tamr VM and EMR to communicate without traversing the internet
* Updates minimal and complete examples to allow the use of interface endpoint

## v0.1.0 - July 20th 2021
* Added minimal VPC, NACLs, S3 VPC Endpoint and optional public subnets and NAT gateway
* Added example with ALB and optional TLS Certificate
