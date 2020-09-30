terraform {
  required_version = "~> 0.13.0"

  required_providers {
    aws = "~> 3.8.0"
  }

  backend "s3" {
    bucket = "ahs-terraform-states"
    key = "ahs/prod/database/terraform.tfstate"
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

data "terraform_remote_state" "common" {
  backend = "s3"

  config = {
    bucket = "ahs-terraform-states"
    key    = "ahs/prod/common/terraform.tfstate"
    region = "eu-central-1"
    shared_credentials_file = "../aws-credentials"
    profile = "aws-training"
  }
}

data "terraform_remote_state" "vpc" {
  backend = "s3"

  config = {
    bucket = "ahs-terraform-states"
    key    = "ahs/prod/vpc/terraform.tfstate"
    region = "eu-central-1"
    shared_credentials_file = "../aws-credentials"
    profile = "aws-training"
  }
}

resource "aws_db_subnet_group" "db-subnet-group" {
  name       = "ahs-db-subnet-group"
  subnet_ids = data.terraform_remote_state.vpc.outputs.private_subnets

  tags = {
    Name = "db-subnet-group"
    team = var.team
  }
}

resource "random_password" "sql-password" {
  length  = 16
  special = false
}

resource "aws_db_instance" "ahs-db-1" {
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "8.0.20"
  instance_class       = "db.t2.micro"
  name                 = "${var.team}db"
  username             = "admin"
  password             = random_password.sql-password.result
  db_subnet_group_name = aws_db_subnet_group.db-subnet-group.name
  vpc_security_group_ids = [data.terraform_remote_state.common.outputs.db-sg-id]
  skip_final_snapshot = true

  tags = {
    Name = "${var.team}-db-1"
    team = var.team
  }
}
