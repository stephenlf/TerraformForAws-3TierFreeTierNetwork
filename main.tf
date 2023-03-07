terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.57"
    }
  }
  required_version = ">= 1.3.9"
}

provider "aws"  {
  region = var.Region
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "AmazonLinux2" {
  most_recent = true
  filter {
    name = "name"
    values = ["amzn2-ami-kernel-5.10-hvm-*-x86_64-gp2"]
  }
}

resource "aws_vpc" "VPC" {
  cidr_block = var.VpcCidr
  tags = {
    "Name" = "${var.EnvironmentName} VPC"
    "Watermark" = var.watermark
  }
}

resource "aws_internet_gateway" "InternetGateway" {
  tags = {
    "Name" = "${var.EnvironmentName} Internet Gateway"
    "Watermark" = var.watermark
  }
}

resource "aws_internet_gateway_attachment" "InternetGatewayAttachement" {
  internet_gateway_id = aws_internet_gateway.InternetGateway.id
  vpc_id = aws_vpc.VPC.id
}

resource "aws_subnet" "PublicSubnet1" {
  vpc_id = aws_vpc.VPC.id
  availability_zone = data.aws_availability_zones.available.names[0]
  cidr_block = var.PublicSubnet1CIDR
  map_public_ip_on_launch = true
  tags = {
    "Name" = "${var.EnvironmentName} PublicSubnet1"
    "Watermark" = var.watermark
  }
}

resource "aws_subnet" "PublicSubnet2" {
  vpc_id = aws_vpc.VPC.id
  availability_zone = data.aws_availability_zones.available.names[0]
  cidr_block = var.PublicSubnet2CIDR
  map_public_ip_on_launch = true
  tags = {
    "Name" = "${var.EnvironmentName} PublicSubnet2"
    "Watermark" = var.watermark
  }
}

resource "aws_subnet" "PrivateAppSubnet1" {
  vpc_id = aws_vpc.VPC.id
  availability_zone = data.aws_availability_zones.available.names[0]
  cidr_block = var.PrivateAppSubnet1CIDR
  map_public_ip_on_launch = false
  tags = {
    "Name" = "${var.EnvironmentName} PrivateAppSubnet1"
    "Watermark" = var.watermark
  }
}

resource "aws_subnet" "PrivateAppSubnet2" {
  vpc_id = aws_vpc.VPC.id
  availability_zone = data.aws_availability_zones.available.names[0]
  cidr_block = var.PrivateAppSubnet2CIDR
  map_public_ip_on_launch = false
  tags = {
    "Name" = "${var.EnvironmentName} PrivateAppSubnet2"
    "Watermark" = var.watermark
  }
}

resource "aws_subnet" "PrivateDBSubnet1" {
  vpc_id = aws_vpc.VPC.id
  availability_zone = data.aws_availability_zones.available.names[0]
  cidr_block = var.PrivateDBSubnet1CIDR
  map_public_ip_on_launch = false
  tags = {
    "Name" = "${var.EnvironmentName} PrivateDBSubnet1"
    "Watermark" = var.watermark
  }
}

resource "aws_subnet" "PrivateDBSubnet2" {
  vpc_id = aws_vpc.VPC.id
  availability_zone = data.aws_availability_zones.available.names[0]
  cidr_block = var.PrivateDBSubnet2CIDR
  map_public_ip_on_launch = false
  tags = {
    "Name" = "${var.EnvironmentName} PrivateDBSubnet2"
    "Watermark" = var.watermark
  }
}

resource "aws_default_security_group" "DefaultSecurityGroup" {
  vpc_id = aws_vpc.VPC.id

  # The same rules that AWS provides by default but under management by Terraform
  ingress {
    protocol  = -1
    self      = true
    from_port = 0
    to_port   = 0
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "NATSecurityGroup" {
  name = "${var.EnvironmentName} NATSecurityGroup"
  vpc_id = aws_vpc.VPC.id
  revoke_rules_on_delete = true
  lifecycle {
    # Necessary if changing 'name' property.
    create_before_destroy = true
  }
  tags = {
    "Watermark" = var.watermark
  }
}

resource "aws_vpc_security_group_ingress_rule" "HTTPin" {
  security_group_id = aws_security_group.NATSecurityGroup.id

  ip_protocol = "tcp"
  cidr_ipv4 = "0.0.0.0/0"
  from_port = 80
  to_port = 80
  description = "HTTP in"
}

resource "aws_vpc_security_group_ingress_rule" "HTTPSin" {
  security_group_id = aws_security_group.NATSecurityGroup.id
  
  ip_protocol = "tcp"
  cidr_ipv4 = "0.0.0.0/0"
  from_port = 443
  to_port = 443
  description = "HTTPS in"
}

resource "aws_vpc_security_group_egress_rule" "HTTPout" {
  security_group_id = aws_security_group.NATSecurityGroup.id

  ip_protocol = "tcp"
  cidr_ipv4 = "0.0.0.0/0"
  from_port = 80
  to_port = 80
  description = "HTTP out"
}

resource "aws_vpc_security_group_egress_rule" "HTTPSout" {
  security_group_id = aws_security_group.NATSecurityGroup.id
  
  ip_protocol = "tcp"
  cidr_ipv4 = "0.0.0.0/0"
  from_port = 443
  to_port = 443
  description = "HTTPS out"
}

resource "aws_instance" "NatInstance1" {
  ami = data.aws_ami.AmazonLinux2.id
  instance_type = "t2.micro"

  availability_zone = data.aws_availability_zones.available.names[0]
  subnet_id = aws_subnet.PublicSubnet1.id
  associate_public_ip_address = true

  source_dest_check = false
  vpc_security_group_ids = [aws_security_group.NATSecurityGroup.id]

  tags = {
    "Name" = "${var.EnvironmentName} NATInstance1"
    "Watermark" = var.watermark
  }
  volume_tags = {
    "Name" = "${var.EnvironmentName} NATInstance1"
    "Watermark" = var.watermark
  }
  
  user_data = <<EOF
    #!/bin/bash
    sysctl -w net.ipv4.ip_forward=1
    iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

    
    EOF
}

resource "aws_route_table" "PrivateRouteTable" {
  vpc_id = aws_vpc.VPC.id
  tags = {
    "Name" = "${var.EnvironmentName} PrivateRouteTable"
    "Watermark" = var.watermark
  }
}

resource "aws_route_table" "PublicRouteTable" {
  vpc_id = aws_vpc.VPC.id
  tags = {
    "Name" = "${var.EnvironmentName} PublicRouteTable"
    "Watermark" = var.watermark
  }
}

resource "aws_route" "PublicInternetRoute" {
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.InternetGateway.id
  route_table_id = aws_route_table.PublicRouteTable.id
}

resource "aws_route" "PrivateInternetRoute" {
  destination_cidr_block = "0.0.0.0/0"
  network_interface_id = aws_instance.NatInstance1.primary_network_interface_id
  route_table_id = aws_route_table.PrivateRouteTable.id
}

resource "aws_route_table_association" "Public1Association" {
  route_table_id = aws_route_table.PublicRouteTable.id
  subnet_id = aws_subnet.PublicSubnet1.id
}

resource "aws_route_table_association" "Public2Association" {
  route_table_id = aws_route_table.PublicRouteTable.id
  subnet_id = aws_subnet.PublicSubnet2.id
}

resource "aws_route_table_association" "PrivateApp1Association" {
  route_table_id = aws_route_table.PrivateRouteTable.id
  subnet_id = aws_subnet.PrivateAppSubnet1.id
}

resource "aws_route_table_association" "PrivateApp2Association" {
  route_table_id = aws_route_table.PrivateRouteTable.id
  subnet_id = aws_subnet.PrivateAppSubnet2.id
}

resource "aws_route_table_association" "PrivateDB1Association" {
  route_table_id = aws_route_table.PrivateRouteTable.id
  subnet_id = aws_subnet.PrivateDBSubnet1.id
}

resource "aws_route_table_association" "PrivateDB2Association" {
  route_table_id = aws_route_table.PrivateRouteTable.id
  subnet_id = aws_subnet.PrivateDBSubnet2.id
}

output "VpcId" {
  value = aws_vpc.VPC.id
  description = "VPC ID"
}

output "InternetGatewayId" {
  value = aws_internet_gateway.InternetGateway.id
  description = "Internet Gateway ID"
}

output "PublicSubnet1Id" {
  value = aws_subnet.PublicSubnet1.id
  description = "Public subnet 1 ID"
}

output "PublicSubnet2Id" {
  value = aws_subnet.PublicSubnet2.id
  description = "Public subnet 2 ID"
}

output "PrivateAppSubnet1Id" {
  value = aws_subnet.PrivateAppSubnet1.id
  description = "Private app subnet 1 ID"
}

output "PrivateAppSubnet2Id" {
  value = aws_subnet.PrivateAppSubnet2.id
  description = "Private app subnet 2 ID"
}

output "PrivateDBSubnet1Id" {
  value = aws_subnet.PrivateDBSubnet1.id
  description = "Private database subnet 1 ID"
}

output "PrivateDBSubnet2Id" {
  value = aws_subnet.PrivateDBSubnet2.id
  description = "Private database subnet 2 ID"
}

output "NatInstancePublicIp" {
  value = aws_instance.NatInstance1.public_ip
  description = "NAT Instance public IP"
}