terraform {
  required_version = "~> 0.13.0"

  required_providers {
    aws = "~> 3.8.0"
  }

  backend "s3" {
    bucket = "ahs-terraform-states"
    key = "ahs/prod/eks-vpc/terraform.tfstate"
    region = "eu-central-1"
    dynamodb_table = "ahs-terraform-state-lock-table"
    encrypt = true

    shared_credentials_file = "../../terraform-basic-practice/aws-credentials"
    profile = "aws-training"
  }

}

provider "aws" {
  shared_credentials_file = "../../terraform-basic-practice/aws-credentials"
  profile                 = "aws-training"
  region                  = "eu-central-1"
}

module "vpc" {
  source = "github.com/DennisCreutz/terraform-modules/mgmt/standardVPC"
  name = "${var.team}-vpc"
  private_subnet_cidrs = ["192.168.0.0/19", "192.168.32.0/19", "192.168.64.0/19"]
  private_subnet_names = ["${var.team}-sn-1-private", "${var.team}-sn-2-private", "${var.team}-sn-3-private"]
  project_name = "${var.team}-eks"
  public_subnet_cidr = "192.168.96.0/19"
  stage_name = var.stage
  aws_vpc_cidr = "192.168.0.0/16"
  aws_create_nat = true
  aws_kubernetes_tagging = true
  aws_kubernetes_cluster_name = "${var.team}-cluster"
  public_subnet_name = "${var.team}-sn-1-public"
}