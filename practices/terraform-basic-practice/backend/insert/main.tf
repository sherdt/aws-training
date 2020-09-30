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

    shared_credentials_file = "../../aws-credentials"
    profile = "aws-training"
  }
}

provider "aws" {
  shared_credentials_file = "../../aws-credentials"
  profile                 = "aws-training"
  region                  = "eu-central-1"
}


data "terraform_remote_state" "common" {
  backend = "s3"

  config = {
    bucket = "ahs-terraform-states"
    key    = "ahs/${var.stage}/common/terraform.tfstate"
    region = "eu-central-1"
    shared_credentials_file = "../../aws-credentials"
    profile = "aws-training"
  }
}

data "terraform_remote_state" "vpc" {
  backend = "s3"

  config = {
    bucket = "ahs-terraform-states"
    key    = "ahs/${var.stage}/vpc/terraform.tfstate"
    region = "eu-central-1"
    shared_credentials_file = "../../aws-credentials"
    profile = "aws-training"
  }
}

data "terraform_remote_state" "database" {
  backend = "s3"

  config = {
    bucket = "ahs-terraform-states"
    key    = "ahs/${var.stage}/database/terraform.tfstate"
    region = "eu-central-1"
    shared_credentials_file = "../../aws-credentials"
    profile = "aws-training"
  }
}

# Zip's your lambda files. Don't forget to add *.zip to your gitignore.
data "archive_file" "lambda_app" {
  type        = "zip"
  output_path = "${path.module}/${local.lambdaName}.zip"
  source_dir  = "${path.module}/app"
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role =  data.terraform_remote_state.common.outputs.ahs-lambda-iam-role.name
  policy_arn = data.terraform_remote_state.common.outputs.ahs-lambda-logging-policy-arn
}

resource "aws_iam_role_policy_attachment" "lambda_eni" {
  role = data.terraform_remote_state.common.outputs.ahs-lambda-iam-role.name
  policy_arn =  data.terraform_remote_state.common.outputs.ahs-lambda-eni-policy-arn
}

resource "aws_lambda_function" "insert_object" {
  filename         = "${local.lambdaName}.zip"
  function_name    = "${var.stage}-${local.lambdaName}"
  role = data.terraform_remote_state.common.outputs.ahs-lambda-iam-role.arn
  handler          = "${local.lambdaName}.handler"
  source_code_hash = data.archive_file.lambda_app.output_base64sha256
  runtime          = "nodejs12.x"

  vpc_config {
    security_group_ids = [data.terraform_remote_state.common.outputs.lambda-sg-id]
    subnet_ids         = data.terraform_remote_state.vpc.outputs.private_subnets
  }

  environment {
    variables = {
      DB_HOST = data.terraform_remote_state.database.outputs.database.address
      DB_PORT = data.terraform_remote_state.database.outputs.database.port
      DB      = data.terraform_remote_state.database.outputs.database.name
      DB_USER = data.terraform_remote_state.database.outputs.database.username
      DB_PW = data.terraform_remote_state.database.outputs.database.password
    }
  }

  tags = local.default_tags
}

