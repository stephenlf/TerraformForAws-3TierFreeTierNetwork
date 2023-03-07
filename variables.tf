variable "Region" {
  description = "The region in which to initialize the VPC"
  type = string
  default = "us-east-1"
}

variable "EnvironmentName" {
    description = "An environment name that is prefixed to resource names"
    type = string
    default = ""
}

variable "VpcCidr" {
    description = "IP Range (CIDR notation) for this VPC"
    type = string
    default = "10.0.0.0/16"
    validation {
      condition = can(regex("(\\d{1,3}).(\\d{1,3}).(\\d{1,3}).(\\d{1,3})/(\\d{1,2})",var.VpcCidr))
      error_message = "must be a valid IP CIDR range of the form x.x.x.x/x"
    }
}

variable "PublicSubnet1CIDR" {
    description = "IP Range (CIDR notation) for the public subnet in the first Availability Zone"
    type = string
    default = "10.0.10.0/24"  
    validation {
      condition = can(regex("(\\d{1,3}).(\\d{1,3}).(\\d{1,3}).(\\d{1,3})/(\\d{1,2})",var.PublicSubnet1CIDR))
      error_message = "must be a valid IP CIDR range of the form x.x.x.x/x"
    }
}

variable "PublicSubnet2CIDR" {
    description = "IP Range (CIDR notation) for the public subnet in the second Availability Zone"
    type = string
    default = "10.0.11.0/24"  
    validation {
      condition = can(regex("(\\d{1,3}).(\\d{1,3}).(\\d{1,3}).(\\d{1,3})/(\\d{1,2})",var.PublicSubnet2CIDR))
      error_message = "must be a valid IP CIDR range of the form x.x.x.x/x"
    }
}

variable "PrivateAppSubnet1CIDR" {
    description = "IP Range (CIDR notation) for the public subnet in the first Availability Zone"
    type = string
    default = "10.0.20.0/24"
    validation {
      condition = can(regex("(\\d{1,3}).(\\d{1,3}).(\\d{1,3}).(\\d{1,3})/(\\d{1,2})",var.PrivateAppSubnet1CIDR))
      error_message = "must be a valid IP CIDR range of the form x.x.x.x/x"
    }  
}

variable "PrivateAppSubnet2CIDR" {
    description = "IP Range (CIDR notation) for the public subnet in the second Availability Zone"
    type = string
    default = "10.0.21.0/24"
    validation {
      condition = can(regex("(\\d{1,3}).(\\d{1,3}).(\\d{1,3}).(\\d{1,3})/(\\d{1,2})",var.PrivateAppSubnet2CIDR))
      error_message = "must be a valid IP CIDR range of the form x.x.x.x/x"
    }  
}

variable "PrivateDBSubnet1CIDR" {
    description = "IP Range (CIDR notation) for the public subnet in the first Availability Zone"
    type = string
    default = "10.0.30.0/24"
    validation {
      condition = can(regex("(\\d{1,3}).(\\d{1,3}).(\\d{1,3}).(\\d{1,3})/(\\d{1,2})",var.PrivateDBSubnet1CIDR))
      error_message = "must be a valid IP CIDR range of the form x.x.x.x/x"
    }  
}

variable "PrivateDBSubnet2CIDR" {
    description = "IP Range (CIDR notation) for the public subnet in the second Availability Zone"
    type = string
    default = "10.0.31.0/24"
    validation {
      condition = can(regex("(\\d{1,3}).(\\d{1,3}).(\\d{1,3}).(\\d{1,3})/(\\d{1,2})",var.PrivateDBSubnet2CIDR))
      error_message = "must be a valid IP CIDR range of the form x.x.x.x/x"
    }  
}

variable "watermark" {
    type = string
    default = "https://github.com/stephenlf/AWS-Free-Tier-Three-Tier-WordPress"
}