/*
Use this VPC for all resources.
You can use a terraform_remote_state of type local to reference to the output of this module.

TODO:
Add
- VPC
- 3 public subnets
- 3 private subnets
- Internet Gateway
- Route table (table, route, association) for public subnets with a route to the internet gateway
- Don't forget to export the resources in the output!
*/

# Datasource to get availability zones needed for the subnets
data "aws_availability_zones" "available" {
  state = "available"
}
