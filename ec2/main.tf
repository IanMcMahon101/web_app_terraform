########################
#
#      AMI Lookup
#
########################

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-trusty-14.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}


data "aws_ami" "rhel" {
  most_recent = true

  filter {
    name   = "name"
    values = ["RHEL-8."]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["309956199498"]
}

########################
#
#      Subnet Lookup
#
########################

data "aws_subnet" "private" {
  id = var.private_subnet_id
}

data "aws_subnet" "public" {
  id = var.public_subnet_id
}

########################
#
#        KMS
#
########################

resource "aws_kms_key" "kms" {
  count       = var.create_webapp ? 1 : 0
  description = "KMS key for instance volumes"

}

resource "aws_kms_alias" "kms_a" {
  count         = var.create_webapp ? 1 : 0
  name          = "alias/ec2-kms-key"
  target_key_id = aws_kms_key.kms.id
}

########################
#
#    Security Groups
#
########################

resource "aws_security_group" "ssh" {
  name   = "allow_ssh"
  vpc_id = var.vpc_id
  ingress = {
    description = "ssh access"
    from_port   = 22
    to_port     = 22
    protocol    = "TCP"
    cidr_blocks = var.ssh_cidr_block
  }

  egress = {
    cidr_blocks = var.egress_cidr_blocks
    description = "egress traffic"
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
  }

}

resource "aws_security_group" "pub_lb" {
  name   = "public_lb"
  vpc_id = var.vpc_id

  ingress = {
    description = "public load balancer ssh"
    from_port   = 443
    to_port     = 443
    protocol    = "TCP"
    cidr_blocks = "0.0.0.0/0" # assuming public
  }

  egress = {
    cidr_blocks = data.aws_subnet.private.cidr_block
    description = "egress traffic"
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
  }

}

resource "aws_security_group" "ec2" {
  name   = "lb_to_ec2"
  vpc_id = var.vpc_id

  ingress = {
    description     = "ssh access"
    from_port       = 80
    to_port         = 80
    protocol        = "TCP"
    security_groups = aws_security_group.pub_lb.id
  }

}

########################
#
#        ASG
#
########################

resource "aws_ebs_encryption_by_default" "ebs" {
  enabled = true
}

resource "aws_ebs_default_kms_key" "key" {
  key_arn = aws_kms_key.kms.arn
}

resource "aws_launch_configuration" "lc" {
  name          = var.lc_name
  image_id      = local.ami_id
  instance_type = var.instance_type
  user_data     = local.user_data
  key_name = var.key_name
  security_groups = [
    aws_security_group.ec2.id,

  ]
  iam_instance_profile = var.instance_profile

  root_block_device = {
    volume_type = var.root_volume_type
    volume_size = var.root_volume_size
    encrypted   = true
  }

  ebs_block_device = {
    volume_type = var.ebs_volume_type
    volume_size = var.ebs_volume_size
    encrypted   = true
  }
}

resource "aws_autoscaling_group" "grp" {
  vpc_zone_identifier  = [data.aws_subnet.private.id]
  name                 = "ASG"
  max_size             = var.asg_max
  min_size             = var.asg_min
  desired_capacity     = var.asg_desired
  health_check_type    = "ELB"
  force_delete         = true
  launch_configuration = aws_launch_configuration.lc.name

}

## using a for each loop with an object variable allows for greater customization on resources that can have many options

resource "aws_autoscaling_policy" "scale" {
  for_each               = var.as_pol
  name                   = each.value.name
  autoscaling_group_name = aws_autoscaling_group.grp.name
  scaling_adjustment     = each.value.scaling_adjustment
  adjustment_type        = each.value.adj_type
  cooldown               = each.value.cooldown

}

########################
#
#     Load Balancer
#
########################

resource "aws_lb" "lb" {
  for_each           = var.alb
  name               = each.value.name
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.pub_lb.id]

  subnet_mapping = {
    subnet_id     = var.public_subnet_id
    allocation_id = var.eip_id
  }

  enable_deletion_protection = each.value.protect
}

resource "aws_lb_target_group" "tg" {
  for_each = var.alb
  name     = "${each.value.name}-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id
}

resource "aws_autoscaling_attachment" "asg_attachment_bar" {
  for_each               = var.alb
  autoscaling_group_name = aws_autoscaling_group.grp.id
  alb_target_group_arn   = aws_lb_target_group.tf[each.key].arn
}

########################
#
#      CW Alarms
#
########################

resource "aws_cloudwatch_metric_alarm" "alarm" {
  for_each            = var.high_mem_alarm
  alarm_name          = each.value.name
  comparison_operator = each.value.comp_op
  evaluation_periods  = each.value.eval_per
  metric_name         = each.value.metric_name
  namespace           = each.value.namespace
  period              = each.value.period
  statistic           = each.value.statistic
  threshold           = each.value.threshold
  alarm_description   = each.value.description
}