output "vpc_id" {
  value = aws_vpc.vpc.id
}

output "private_subnets" {
  value = aws_subnet.private_subnet.*.id
}