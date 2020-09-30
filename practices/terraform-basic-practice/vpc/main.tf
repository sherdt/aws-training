terraform {
  required_version = "~> 0.13.0"

  required_providers {
    aws = "~> 3.8.0"
  }

  backend "s3" {
    bucket = "ahs-terraform-states"
    region = "eu-central-1"
    dynamodb_table = "ahs-terraform-state-lock-table"
    encrypt = true

    shared_credentials_file = "../aws-credentials"
    profile = "aws-training"
  }

}

provider "aws" {
  shared_credentials_file = "../aws-credentials"
  profile                 = "aws-training"
  region                  = "eu-central-1"
}

# Datasource to get availability zones needed for the subnets
data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/20"

  tags = {
    "Name" : "${var.team}-${var.stage}-vpc"
    "team" : var.team
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.stage}-igw"
    "team" : var.team
  }
}

resource "aws_subnet" "public_subnet" {
  count = 3
  cidr_block = "10.0.${count.index * 2}.0/23"

  vpc_id            = aws_vpc.vpc.id
  availability_zone = data.aws_availability_zones.available.names[count.index % length(data.aws_availability_zones.available.names)]

  tags = {
    Name = "${var.stage}-public-${count.index}"
    "team" : var.team
  }
}

resource "aws_subnet" "private_subnet" {
  count = 3
  cidr_block = "10.0.${(count.index + 3) * 2 }.0/23"

  vpc_id            = aws_vpc.vpc.id
  availability_zone = data.aws_availability_zones.available.names[count.index % length(data.aws_availability_zones.available.names)]

  tags = {
    Name = "${var.stage}-private-${count.index}"
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
    Name = "${var.stage}-public"
    "team" : var.team
  }
}

resource "aws_route_table_association" "public_subnet" {
  count = 3

  subnet_id      = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.public.id
}
