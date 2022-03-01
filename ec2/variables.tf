variable "public_subnet_id" {
  type    = string
  default = ""
}

variable "private_subnet_id" {
  type    = string
  default = ""
}

variable "vpc_id" {
  type    = string
  default = ""
}

variable "os" {
  type    = string
  default = ""
}

variable "lc_name" {
  type        = string
  default     = ""
  description = "launch configuration name"
}

variable "instance_type" {
  type    = string
  default = ""
}

variable "instance_profile" {
  type    = string
  default = ""
}

variable "ssh_user" {
  type        = string
  default     = ""
  description = "domain group that will allow ssh access"
}

variable "pub_key" {
  type        = string
  default     = ""
  description = "domain group that will allow ssh access"
}

variable "key_name" {
  type = string
  default = ""
}

variable "sudo" {
  type = bool
  default = false
}

variable "ssh_cidr_blocks" {
  type    = list(string)
  default = []
}

variable "egress_cidr_blocks" {
  type    = list(string)
  default = []
}

variable "root_volume_type" {
  type    = string
  default = ""
}

variable "root_volume_size" {
  type    = number
  default = 10
}

variable "ebs_volume_type" {
  type    = number
  default = 10
}

variable "ebs_volume_size" {
  type    = number
  default = 10
}

variable "asg_max" {
  type    = number
  default = 2
}

variable "asg_min" {
  type    = number
  default = 1
}

variable "asg_desired" {
  type    = number
  default = 1
}

variable "eip_ip" {
  type    = string
  default = ""
}

variable "as_pol" {
  type = map(object({
    name               = string
    scaling_adjustment = number
    adj_type           = string
    cooldown           = number
  }))
}

variable "alb" {
  type = map(object({
    name    = string
    protect = bool
  }))
}

variable "high_mem_alarm" {
  type = map(object({
    name        = string
    comp_op     = string
    eval_per    = string
    namespace   = string
    metric_name = string
    period      = number
    statistic   = string
    threshold   = string
    description = string
  }))
}

locals {
  ami_id = var.os == "ubuntu" ? data.aws_ami.ubuntu.id : var.os == "rhel" ? data.aws_ami.rhel.id : null

  user_data = var.sudo ? templatefile("${path.module}/user_data/user_data_sudo.tmpl", { ssh_user = var.ssh_user, pub_key = var.pub_key }) : templatefile("${path.module}/user_data/user_data.tmpl", { ssh_user = var.ssh_user, pub_key = var.pub_key })
}