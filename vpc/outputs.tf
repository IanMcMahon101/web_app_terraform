output "public_subnet" {
  value = aws_subnet.subnets["public"].id
}
output "private_subnet" {
  value = aws_subnet.subnets["private"].id
}
output "vpc_id" {
  value = aws_vpc.vpc.id
}
output "eip_id" {
  value = aws_eip.lb_eip.id
}