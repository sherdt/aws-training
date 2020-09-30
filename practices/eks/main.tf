terraform {
  required_version = "~> 0.13.0"

  required_providers {
    aws = "~> 3.8.0"
  }

  backend "s3" {
    bucket = "ahs-terraform-states"
    key = "ahs/prod/eks/terraform.tfstate"
    region = "eu-central-1"
    dynamodb_table = "ahs-terraform-state-lock-table"
    encrypt = true

    shared_credentials_file = "../terraform-basic-practice/aws-credentials"
    profile = "aws-training"
  }

}

provider "aws" {
  shared_credentials_file = "../terraform-basic-practice/aws-credentials"
  profile = "aws-training"
  region = "eu-central-1"
}

data "aws_region" "current" {}

data "terraform_remote_state" "vpc" {
  backend = "s3"

  config = {
    bucket = "ahs-terraform-states"
    key = "ahs/prod/eks-vpc/terraform.tfstate"
    region = "eu-central-1"
    shared_credentials_file = "../terraform-basic-practice/aws-credentials"
    profile = "aws-training"

  }
}

# Policies
resource "aws_iam_role" "cluster" {
  name = "${var.stage}-${terraform.workspace}-cluster-policy"

  tags = local.default_tags
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role = aws_iam_role.cluster.name
}

resource "aws_iam_role_policy_attachment" "service_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role = aws_iam_role.cluster.name
}

# Security Groups
resource "aws_security_group" "cluster" {
  name = "${local.name}-security-group"
  description = "Cluster communication with worker nodes"
  vpc_id = data.terraform_remote_state.vpc.outputs.vpc_created.id

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [
      "0.0.0.0/0"]
  }

  tags = local.default_tags
}

resource "aws_security_group_rule" "cluster_workstation_ingress" {
  cidr_blocks = [
    "0.0.0.0/0"]
  description = "Allow workstation to communicate with the cluster API Server"
  from_port = 443
  protocol = "tcp"
  security_group_id = aws_security_group.cluster.id
  to_port = 443
  type = "ingress"
}

# EKS
# TODO
resource "aws_eks_cluster" "eks" {

  vpc_config {
    endpoint_private_access = false
    endpoint_public_access = true
    subnet_ids = data.terraform_remote_state.vpc.outputs.aws_private_subnets_ids
  }

  enabled_cluster_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"]

  tags = local.default_tags

  depends_on = [
    aws_iam_role_policy_attachment.cluster_policy,
    aws_iam_role_policy_attachment.service_policy
  ]

  name = "ahs-cluster"
  role_arn = aws_iam_role.cluster.arn
}

