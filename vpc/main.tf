data "aws_availability_zones" "azs" {}

resource "aws_vpc" "vpc" {
  count                          = var.create_vpc ? 1 : 0
  cidr_block                     = var.cidr_block
  enable_dns_support             = var.dns_support
  enable_dns_hostnames           = var.dns_hostnames
  instance_tenancy               = var.instance_tenancy
  enable_classiclink             = var.classic_link
  enable_classiclink_dns_support = var.enable_classiclink_dns

  tags = merge(
    var.tags,
    {
      Name = var.vpc_name
    }
  )
}

########################
#
#        IGW
#
########################

resource "aws_internet_gateway" "igw" {
  count  = var.create_vpc ? 1 : 0
  vpc_id = aws_vpc.vpc.id

  tags = merge(
    var.tags,
    {
      Name = "${var.vpc_name}-igw"
    }
  )

  depends_on = [
    aws_vpc.vpc
  ]
}

########################
#
#        EIP
#
########################

resource "aws_eip" "eip" {
  count = var.create_vpc ? 1 : 0
  vpc   = var.create_vpc

  tags = merge(
    var.tags,
    {
      Name = "${var.vpc_name}-eip"
    }
  )
}

resource "aws_eip" "lb_eip" {
  count = var.create_vpc ? 1 : 0
  vpc   = var.create_vpc

  tags = merge(
    var.tags,
    {
      Name = "${var.vpc_name}-lb-eip"
    }
  )
}

########################
#
#    Public Subnets
#
########################

resource "aws_subnet" "subnets" {
  for_each                = var.subnets
  cidr_block              = cidrsubnet(aws_vpc.vpc.cidr_block, each.value.newbits, each.value.netnum)
  vpc_id                  = aws_vpc.vpc.id
  map_public_ip_on_launch = each.value.public
  availability_zone       = data.aws_availability_zones.azs.names[index(var.subnets, each.value) + 1] # get numerical index of for_each loop

  tags = merge(
    var.tags,
    {
      Name = each.value.subnet_name
    }
  )

  depends_on = [
    aws_vpc.vpc,
    data.aws_availability_zones.azs
  ]
}

########################
#
# NGW For Private Subnets
#
########################

resource "aws_nat_gateway" "ngw" {
  count         = var.create_vpc ? 1 : 0
  allocation_id = aws_eip.eip[count.index].id
  subnet_id     = aws_subnet.subnets["public"].id

  tags = merge(
    var.tags,
    {
      Name = "${var.vpc_name}-ngw"
    }
  )

  depends_on = [
    aws_eip.eip,
    aws_vpc.vpc,
    aws_subnet.subnets
  ]
}

########################
#
#     Route Tables
#
########################

resource "aws_route_table" "rtb" {
  for_each = var.subnets
  vpc_id   = aws_vpc.vpc.id

  route = {
    cidr_block = "0.0.0.0/0"
    gateway_id = each.value.public ? aws_internet_gateway.igw.id : aws_nat_gateway.ngw.id
  }

  tags = merge(
    var.tags,
    {
      Name = each.value.public ? "public route table" : "private route table"
    }
  )

  depends_on = [
    aws_internet_gateway.igw,
    aws_nat_gateway.ngw,
    aws_subnet.subnets
  ]
}

resource "aws_route_table_association" "assoc" {
  for_each       = var.subnets
  route_table_id = aws_route_table.rtb[each.key].id
  subnet_id      = aws_subnet.subnets[each.key].id

  depends_on = [
    aws_subnet.subnets,
    aws_route_table.rtb
  ]
}