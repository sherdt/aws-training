output "vpc_created" {
  value      = module.vpc.aws_vpc_created
}
output "private_subnets" {
  value = module.vpc.aws_private_subnets_ids
}
output "public_subnet1" {
  value = module.vpc.aws_public_subnet_created
}
output "addition_subnet_ids" {
  value = module.vpc.aws_additional_public_sebnet_ids
}
