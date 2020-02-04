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

provider "aws" {
  region     = "eu-central-1"
  access_key = var.aws_credentials.access_key # TODO
  secret_key = var.aws_credentials.secret_key # TODO
}

# Datasource to get availability zones needed for the subnets
data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "this" {}
resource "aws_internet_gateway" "this" {}

resource "aws_subnet" "public_subnet" {}
resource "aws_subnet" "private_subnet" {}

resource "aws_route_table" "public" {}
resource "aws_route_table_association" "public_subnet" {}
