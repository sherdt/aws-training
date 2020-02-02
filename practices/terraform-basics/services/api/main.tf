terraform {
  required_version = "~> 0.12"
  required_providers {
    aws = "~> 2.47"
  }
  backend "s3" {
    bucket         = "terraform-statemanager-store-123812902"
    key            = "live/prodyna-aws-training/prod/services/api/terraform.tfstate"
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

data "terraform_remote_state" "lambda_getObject" {
  backend = "s3"

  config = {
    bucket = "terraform-statemanager-store-123812902"
    key    = "live/prodyna-aws-training/prod/services/backend/getObjects/terraform.tfstate"
    region = "eu-central-1"
  }
}

resource "aws_api_gateway_rest_api" "this" {
  name        = local.name
  description = "Example API for the PRODYNA AWS training."
}

resource "aws_api_gateway_resource" "order" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_rest_api.this.root_resource_id
  path_part   = "order"
}

resource "aws_api_gateway_method" "get" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = aws_api_gateway_resource.order.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "get_objects" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_method.get.resource_id
  http_method = aws_api_gateway_method.get.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = data.terraform_remote_state.lambda_getObject.outputs.lambda_getObject.invoke_arn
}

resource "aws_api_gateway_deployment" "this" {
  depends_on = [
    aws_api_gateway_integration.get_objects,
  ]

  rest_api_id = aws_api_gateway_rest_api.this.id
  stage_name  = "prod"
}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = data.terraform_remote_state.lambda_getObject.outputs.lambda_getObject.function_name
  principal     = "apigateway.amazonaws.com"

  # The "/*/*" portion grants access from any method on any resource
  # within the API Gateway REST API.
  source_arn = "${aws_api_gateway_rest_api.this.execution_arn}/*/*"
}
