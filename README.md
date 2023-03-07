# AWS Free-Tier/Three-Tiered Network
This repo contains Terraform templates and dependencies to create three-tier, secure VPC in two availability zones in your AWS account.

This project serves more to build experience than to solve any practical issues associated with hosting a secure app on AWS. However, some of the cost-saving measures I implemented (such as running a NAT Instance rather than a NAT gateway) may be of interest to individuals or small dev/test teams.

## Table of Contents
1. Installation Instructions
2. Architectural overview
2. Template details

## Installation Instructions
Installation is easy. All you need are the two '.tf' files stored in this repository.
1. Set up the [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) and the [Terraform CLI](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli) and [configure the two to work together](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/aws-build).
1. Save 'main.tf' and 'variables.tf' to a local directory.
1. Using the command line/terminal, navigate to the directory containing the above '.tf' files.
1. Run `terraform init` to initialize the Terraform directory.
1. Run `terraform plan` to review the architecture that will be created.
1. Run `terraform apply` to create the architecture in your AWS account (Terraform will prompt a confirmation). 
1. When you're finished with the architecture, run `terraform destroy` to delete all of the resources that Terraform initialized.

**WARNING: Best efforts have been made to ensure that this architecture is free tier. However, the "free tier" status of the resources this template will spin up is liable to change without notice.** Review the architecture that these templates will create with `terraform plan` before running `terraform apply`.

#### Optional Parameters (Variables)
Parameters may be included during the `terraform apply` stage. Read more about about specifying variables in [Unix shells](https://developer.hashicorp.com/terraform/language/values/variables#variables-on-the-command-line) or the [Windows Command Line](https://developer.hashicorp.com/terraform/cli/commands/plan#input-variables-on-the-command-line). 

<Details><Summary>See variables</Summary>

 |Variable|Default|Description|
 |---|---|---|
 `Region`|us-east-1|The region in which to initialize the VPC
 `EnvironmentName`||An environment name that is prefixed to resource names
 `VpcCidr`|10.0.0.0/16|IP Range (CIDR notation) for the VPC
 `PublicSubnet1CIDR`|10.0.10.0/24|IP Range (CIDR notation) for the public subnet in the first Availability Zone
 `PublicSubnet2CIDR`|10.0.11.0/24|IP Range (CIDR notation) for the public subnet in the second Availability Zone
 `PublicSubnet1CIDR`|10.0.20.0/24|IP Range (CIDR notation) for the private app subnet in the first Availability Zone
 `PublicSubnet2CIDR`|10.0.21.0/24|IP Range (CIDR notation) for the private app subnet in the second Availability Zone
 `PublicSubnet1CIDR`|10.0.30.0/24|IP Range (CIDR notation) for the private data subnet in the first Availability Zone
 `PublicSubnet2CIDR`|10.0.31.0/24|IP Range (CIDR notation) for the private data subnet in the second Availability Zone
 </details>

## Architectural Overview
This network is built on three-tier architecture. The design of the three tiers (presentation tier, app tier, and data tier) is modelled after the [WordPress: Best Practices on AWS](https://aws.amazon.com/blogs/architecture/wordpress-best-practices-on-aws/) whitepaper. 

The three tiers may be populated as follows:
 |Layer|Function|
 |---|---|
 | 1. Presentation tier | Dual purpose NAT Instance/Bastion server [This template configures a NAT Instance only.]
 |2. Application tier | App server [Not included]
 |3. Data Tier|RDS Database [Not included]

Each layer is given its own subnet in a single availability zone (AZ). A second set of subnets is defined in a second AZ, which satisfies the subnet group requirements of RDS and allows for easy scaling in the future.

The VPC connects to the internet through an **Internet Gateway**. Only the presentation layer is a publicly accessible (i.e. has a route to the Internet Gateway defined). 

Note that I opt to create a NAT Instance out of an EC2 instance, rather than use AWS's built-in NAT Gateways. This is a cost-saving measure. See template details for more information

<Details><Summary>See the architectural diagram</summary>
<picture>
  <source media="(prefers-color-scheme: dark)" srcset="/assets/WordPress Architecture DarkMode.jpeg" | width=750>
  <source media="(prefers-color-scheme: light)" srcset="/assets/WordPress Architecture DarkMode.jpeg" | width=750>
  <img alt="A diagram of the architecture that is created with these CloudFormation Templates." src="/assets/WordPress Architecture DarkMode.jpeg" | width=750>
</picture>
</Details>

## Template Details
#### TEMPLATE: main.tf
This template lays down the necessary networking infrastructure for the app and database servers to come. The architecture is initialized in the first two AZs (alphabetically) in the region from which the template is run in CloudFormation. 

Instead of a NAT Gateway (which can cost nearly $40/month), an EC2 instance is spun up and configured to act as a NAT Instance. To be clear, NAT Gateways are better than this NAT Instance in nearly every environment. They are fully managed, scalable, and highly available. I only went with a NAT Instance as a cost-saving measure.

To configure the NAT Instance, I disable `SourceDestCheck` and run the following bootstrap script:
```
#!/bin/bash
sysctl -w net.ipv4.ip_forward=1
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
```
This design of this NAT instance was inspired by a [blog post](https://www.kabisa.nl/tech/cost-saving-with-nat-instances/) by Luk van den Borne from 2019. 

To create a stack in a different region, change the AMI ID to one belonging to an Amazon Linux 2 image in your region.

<Details><Summary>See resources</summary>


 |Resource|Description| 
 |---|---|
 |VPC|A virtual private cloud with the CIDR block specified in the parameters
|InternetGateway|Default Internet Gateway
|InternetGatewayAttachment|Connect Internet Gateway to VPC
|PublicSubnet1 and PublicSubnet2|Makes a call to `"Fn::GetAZs"` to get a list of AZs in the region you are running the template in. Initializes a subnet in the first (Subnet1) or second (Subnet2) AZ in the region (alphabetically). `MapPublicIpOnLaunch` is set to `true`.
|PrivateAppSubnet1/2 and PrivateDBSubnet1/2|Makes a call to `"Fn::GetAZs"` to get a list of AZs in the region you are running the template in. Initializes a subnet in the first (Subnet1) or second (Subnet2) AZ in the region (alphabetically).
|DefaultSecurityGroup|Initializes default security group for Terraform to manage. Not assigned to any instances.
|NATSecurityGroup and HTTP(S)in/out|Security group and rules to be used by the NAT Instance. Enables HTTP/HTTPS communication to and from any IP.
|NATInstance1|Initializes an t2.micro (free-tier) EC2 instance inside PublicSubnet1. The bootstrap script and `SourceDestCheck=false` attribute together enable IP forwarding (i.e. NAT funcationality). The AMI is the pulled by the `data "aws_ami` object and assigns the most recent Amazon Linux 2 x86_64_gp2 image. Double check that this image type is free tier in your target region before applying this template.
|PublicRouteTable and PublicInternetRoute|Creates a route to the internet through the Internet Gateway.
|PrivateRouteTable and PrivateInternetRoute|Creates a route to the internet through the NAT Instance.
|___RouteTableAssociation|Associates each of the subnets with either PublicRouteTable (public subnets) or PrivateRouteTable (private subnets).
</details>

<Details><Summary>See outputs</summary>

 |Output|Description|
 |---|---|
 VpcId|VPC ID
 InternetGatewayId|Internet Gateway ID
 PublicSubnet1Id|Public subnet 1 ID
 PublicSubnet2Id|Public subnet 2 ID
 PrivateAppSubnet1Id|Private app subnet 1 ID
 PrivateAppSubnet2Id|Private app subnet 2 ID
 PrivateDBSubnet1Id|Private database subnet 1 ID
 PrivateDBSubnet2Id|Private database subnet 2 ID
 NatInstancePublicIp|NAT Instance public IP
</details>