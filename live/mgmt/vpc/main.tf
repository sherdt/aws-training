terraform {
  required_version = "~> 0.12"
  required_providers {
    aws = "~> 2.47"
    null = "~> 2.1"
  }
  backend "s3" {
    bucket         = "terraform-statemanager-store-123812902"
    key            = "live/prodyna-aws-training/prod/mgmt/vpc/terraform.tfstate"
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

module "vpc" {
  source = "github.com/DennisCreutz/prodyna-aws-training/modules/mgmt/standardVPC"

  stage_name     = local.stageName
  project_name   = local.projectName
  name           = "${local.stageName}-${terraform.workspace}-vpc"

  public_subnet_cidr = local.public_subnet_cidr
  public_subnet_name = "pub-1"

  private_subnet_cidrs = [local.private_subnet_1_cidr, local.private_subnet_2_cidr, local.private_subnet_3_cidr]
  private_subnet_names = ["priv-1", "priv-2", "priv-3"]

  aws_additional_public_subnet_cidrs = ["10.0.128.0/19", "10.0.160.0/19"]
  aws_additional_public_subnet_names = ["pub-2", "pub-3"]

  aws_vpc_cidr   = local.vpc_cidr
  aws_create_nat = false
}
