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
  shared_credentials_file = "../aws-credentials"
  profile                 = "aws-training"
  region                  = "eu-central-1"

  version = "~> 3.8.0"
}

# Datasource to get availability zones needed for the subnets
data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/20"

  tags = {
    "Name" : "${var.team}-vpc"
    "team" : var.team
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "igw"
    "team" : var.team
  }
}

resource "aws_subnet" "public_subnet" {
  count = 3
  cidr_block = "10.0.${count.index * 2}.0/23"

  vpc_id            = aws_vpc.vpc.id
  availability_zone = data.aws_availability_zones.available.names[count.index % length(data.aws_availability_zones.available.names)]

  tags = {
    Name = "public-${count.index}"
    "team" : var.team
  }
}

resource "aws_subnet" "private_subnet" {
  count = 3
  cidr_block = "10.0.${(count.index + 3) * 2 }.0/23"

  vpc_id            = aws_vpc.vpc.id
  availability_zone = data.aws_availability_zones.available.names[count.index % length(data.aws_availability_zones.available.names)]

  tags = {
    Name = "private-${count.index}"
    "team" : var.team
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public"
    "team" : var.team
  }
}

resource "aws_route_table_association" "public_subnet" {
  count = 3

  subnet_id      = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.public.id
}
