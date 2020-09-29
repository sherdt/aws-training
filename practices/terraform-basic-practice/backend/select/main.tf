provider "aws" {
  shared_credentials_file = "../aws-credentials"
  profile                 = "aws-training"
  region                  = "eu-central-1"

  version = "~> 3.8.0"
}
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role =  data.terraform_remote_state.common.outputs.ahs-lambda-iam-role.name
  policy_arn = data.terraform_remote_state.common.outputs.ahs-lambda-logging-policy-arn
}
resource "aws_iam_role_policy_attachment" "lambda_eni" {
  role = data.terraform_remote_state.common.outputs.ahs-lambda-iam-role.name
  policy_arn =  data.terraform_remote_state.common.outputs.ahs-lambda-eni-policy-arn
}

data "terraform_remote_state" "common" {
  backend = "local"

  config = {
    path = "${path.module}/../../common/terraform.tfstate"
  }
}

data "terraform_remote_state" "vpc" {
  backend = "local"

  config = {
    path = "${path.module}/../../vpc/terraform.tfstate"
  }
}

data "terraform_remote_state" "database" {
  backend = "local"

  config = {
    path = "${path.module}/../../database/terraform.tfstate"
  }
}

resource "aws_lambda_function" "get_objects" {
  filename = "${local.lambdaName}.zip"
  function_name = local.lambdaName
  role = data.terraform_remote_state.common.outputs.ahs-lambda-iam-role.arn
  handler = "${local.lambdaName}.handler"
  source_code_hash = data.archive_file.lambda_app.output_base64sha256
  runtime = "nodejs12.x"

  vpc_config {
    security_group_ids = [data.terraform_remote_state.common.outputs.lambda-sg-id]
    subnet_ids = data.terraform_remote_state.vpc.outputs.private_subnets
  }

  environment {
    variables = {
      DB_HOST = data.terraform_remote_state.database.outputs.database.address
      DB_PORT = data.terraform_remote_state.database.outputs.database.port
      DB = data.terraform_remote_state.database.outputs.database.name

      DB_USER = data.terraform_remote_state.database.outputs.database.username
      DB_PW = data.terraform_remote_state.database.outputs.database.password
    }
  }

  tags = local.default_tags
}

# Zip's your lambda files. Don't forget to add *.zip to your gitignore.
data "archive_file" "lambda_app" {
  type = "zip"
  output_path = "${path.module}/${local.lambdaName}.zip"
  source_dir = "${path.module}/app"
}
