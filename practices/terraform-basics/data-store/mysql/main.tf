terraform {
  required_version = "~> 0.12"
  required_providers {
    aws = "~> 2.47"
  }
  backend "s3" {
    bucket         = "terraform-statemanager-store-123812902"
    key            = "live/prodyna-aws-training/prod/data-store/mysql/terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "terraform-statemanager-lock-db"
    encrypt        = true
  }
}

provider "aws" {
  region     = "eu-central-1"
  access_key = var.aws_credentials.access_key
  secret_key = var.aws_credentials.secret_key
}

data "terraform_remote_state" "vpc" {
  backend = "s3"

  config = {
    bucket = "terraform-statemanager-store-123812902"
    key    = "live/prodyna-aws-training/prod/mgmt/vpc/terraform.tfstate"
    region = "eu-central-1"
  }
}

resource "aws_db_subnet_group" "this" {
  name       = "${local.name}-subnet-group"
  subnet_ids = data.terraform_remote_state.vpc.outputs.private_subnets

  tags = local.default_tags
}

resource "aws_security_group" "allow_all" {
  name        = "${local.name}-node-security-group"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_created.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.default_tags
}

resource "aws_db_instance" "this" {
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t2.micro"
  name                 = local.db_name
  username             = var.db_credentials.user
  password             = var.db_credentials.pw
  parameter_group_name = "default.mysql5.7"
  db_subnet_group_name = aws_db_subnet_group.this.name
  skip_final_snapshot = true
  identifier = lower(local.name)
  vpc_security_group_ids = [aws_security_group.allow_all.id]

  tags = local.default_tags
}
