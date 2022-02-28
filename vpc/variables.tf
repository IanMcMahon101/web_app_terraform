variable "create_vpc" {
  type        = bool
  default     = true
  description = "A boolean flag create vpc if true, or skip/destroy if false."
}

variable "vpc_name" {
  type        = string
  default     = ""
  description = "Name tag for the VPC"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "map object of custom tags"
}

variable "cidr_block" {
  type        = string
  default     = ""
  description = "The CIDR range for the main VPC CIDR"
}

variable "dns_support" {
  type        = bool
  default     = true
  description = "A boolean flag to enable/disable DNS support in the VPC."
}

variable "dns_hostnames" {
  type        = bool
  default     = true
  description = "A boolean flag to enable/disable DNS hostnames in the VPC"
}

variable "instance_tenancy" {
  type        = string
  default     = "default"
  description = "A tenancy option for instances launched into the VPC."
}

variable "enable_classiclink" {
  type        = bool
  default     = false
  description = "A boolean flag to enable/disable ClassicLink for the VPC"
}

variable "enable_classiclink_dns" {
  type        = bool
  default     = false
  description = "A boolean flag to enable/disable ClassicLink DNS Support for the VPC"
}

########################
#
#   Subnet Vairables
#
########################

variable "subnets" {
  type = map(object({
    subnet_name = string
    public      = bool
    newbits     = number
    netnum      = number
  }))
}