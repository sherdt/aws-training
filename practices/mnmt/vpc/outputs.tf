output "vpc_created" {
  value = module.vpc.aws_vpc_created
}

output "aws_private_subnets_ids" {
  value = module.vpc.aws_private_subnets_ids
}