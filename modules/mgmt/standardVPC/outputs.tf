# AWS Output
output "aws_vpc_created" {
  value      = aws_vpc.default
  depends_on = [aws_vpc.default]
}
output "aws_private_subnets_created" {
  value      = aws_subnet.private_subnets
  depends_on = [aws_subnet.private_subnets]
}
output "aws_private_subnets_ids" {
  value      = aws_subnet.private_subnets.*.id
  depends_on = [aws_subnet.private_subnets]
}
output "aws_public_subnet_created" {
  value      = aws_subnet.public_subnet
  depends_on = [aws_subnet.public_subnet]
}
output "aws_additional_public_sebnet_ids" {
  value = aws_subnet.additional_public_subnets.*.id
  depends_on = [aws_subnet.additional_public_subnets]
}
output "aws_nat_created" {
  value      = aws_nat_gateway.nat
  depends_on = [aws_nat_gateway.nat]
}
