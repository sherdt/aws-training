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
  profile = "aws-training"
  region = "eu-central-1"
}

data "terraform_remote_state" "vpc" {
  backend = "s3"

  config = {
    bucket = "ahs-terraform-states"
    key    = "ahs/${var.stage}/vpc/terraform.tfstate"
    region = "eu-central-1"
    shared_credentials_file = "../aws-credentials"
    profile = "aws-training"
  }
}

# Normaly you create a more restrictive security group
resource "aws_security_group" "allow_all" {
  name = "ahs-${var.stage}-node-security-group"
  vpc_id = data.terraform_remote_state.vpc.outputs.vpc_id

  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [
      "0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [
      "0.0.0.0/0"]
  }

  tags = {
    team = var.team
  }
}

resource "aws_security_group" "db-sg" {
  vpc_id = data.terraform_remote_state.vpc.outputs.vpc_id
  name = "db-${var.stage}-sg"

  tags = {
    Name = "db-${var.stage}-sg"
    team = var.team
  }
}

resource "aws_security_group_rule" "db-sg-rule" {
  source_security_group_id = aws_security_group.db-sg.id
  type = "ingress"
  from_port = 3306
  to_port = 3306
  protocol = "tcp"
  security_group_id = aws_security_group.lambda-sg.id
}

resource "aws_security_group" "lambda-sg" {
  vpc_id = data.terraform_remote_state.vpc.outputs.vpc_id
  name = "lambda-${var.stage}-sg"

  egress {
    from_port = 3306
    to_port = 3306
    protocol = "tcp"
    security_groups = [aws_security_group.db-sg.id]
  }

  tags = {
    Name = "lambda-${var.stage}-sg"
    team = var.team
  }
}


/*
  This creates a role for the lambda function.
  Then we can add the logging and eni policy to the role and add the role to the lambda function.
*/
resource "aws_iam_role" "iam-role" {
  name = "${local.name}-${var.stage}-iam-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
  tags = local.default_tags
}

resource "aws_iam_policy" "lambda_logging" {
  name = "${local.name}-${var.stage}-logging-policy"
  path = "/"
  description = "IAM policy for logging from a lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    }
  ]
}
EOF
}

# This policy is needed because we need to create the lambdas in our VP
resource "aws_iam_policy" "lambda_eni" {
  name = "${local.name}-${var.stage}-eni-policy"
  path = "/"
  description = "IAM policy for creating ENI's from a lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ec2:DescribeNetworkInterfaces",
        "ec2:CreateNetworkInterface",
        "ec2:DeleteNetworkInterface"
      ],
      "Resource": "*",
      "Effect": "Allow"
    }
  ]
}
EOF
}