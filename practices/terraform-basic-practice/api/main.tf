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

data "terraform_remote_state" "lambda_getObject" {
  backend = "s3"

  config = {
    bucket = "ahs-terraform-states"
    key    = "ahs/${var.stage}/be-select/terraform.tfstate"
    region = "eu-central-1"
    shared_credentials_file = "../aws-credentials"
    profile = "aws-training"
  }
}

data "terraform_remote_state" "lambda_insertObject" {
  backend = "s3"

  config = {
    bucket = "ahs-terraform-states"
    key    = "ahs/${var.stage}/be-insert/terraform.tfstate"
    region = "eu-central-1"
    shared_credentials_file = "../aws-credentials"
    profile = "aws-training"
  }
}

# The API
resource "aws_api_gateway_rest_api" "this" {
  name        = "ahs-${var.stage}-shop"
  description = "Example API for the PRODYNA AWS training."
}

# API resources
resource "aws_api_gateway_resource" "order" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_rest_api.this.root_resource_id
  path_part   = "order"
}

/*
  API methods
*/
resource "aws_api_gateway_method" "get" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = aws_api_gateway_resource.order.id
  http_method   = "GET"
  authorization = "NONE"
}
resource "aws_api_gateway_method" "post" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = aws_api_gateway_resource.order.id
  http_method   = "POST"
  authorization = "NONE"
}
resource "aws_api_gateway_integration" "get_objects" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_method.get.resource_id
  http_method = aws_api_gateway_method.get.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = data.terraform_remote_state.lambda_getObject.outputs.invoke_arn
}
resource "aws_api_gateway_integration" "insert_object" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_method.post.resource_id
  http_method = aws_api_gateway_method.post.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = data.terraform_remote_state.lambda_insertObject.outputs.invoke_arn
}

resource "aws_api_gateway_method_response" "response_method_get" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.order.id
  http_method = aws_api_gateway_integration.get_objects.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }
}
resource "aws_api_gateway_integration_response" "response_method_get_integration" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.order.id
  http_method = aws_api_gateway_method_response.response_method_get.http_method
  status_code = aws_api_gateway_method_response.response_method_get.status_code

  response_templates = {
    "application/json" = ""
  }
}
resource "aws_api_gateway_method_response" "response_method_post" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.order.id
  http_method = aws_api_gateway_integration.insert_object.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }
}
resource "aws_api_gateway_integration_response" "response_method_post_integration" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.order.id
  http_method = aws_api_gateway_method_response.response_method_post.http_method
  status_code = aws_api_gateway_method_response.response_method_post.status_code

  response_templates = {
    "application/json" = ""
  }
}

# This deploys your API gateway on creation.
# If you update the API gateway the deployment is not executed and needs to be executed over the AWS console.
resource "aws_api_gateway_deployment" "this" {
  depends_on = [
    aws_api_gateway_integration.get_objects,
    aws_api_gateway_integration.insert_object,
  ]

  rest_api_id = aws_api_gateway_rest_api.this.id
  stage_name  = var.stage
}

/*
  Allow the API gateway to invoke the lambda functions
*/
resource "aws_lambda_permission" "apigw_get" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = data.terraform_remote_state.lambda_getObject.outputs.function_name
  principal     = "apigateway.amazonaws.com"

  # The "/*/*" portion grants access from any method on any resource
  # within the API Gateway REST API.
  source_arn = "${aws_api_gateway_rest_api.this.execution_arn}/*/*"
}
resource "aws_lambda_permission" "apigw_insert" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = data.terraform_remote_state.lambda_insertObject.outputs.function_name
  principal     = "apigateway.amazonaws.com"

  # The "/*/*" portion grants access from any method on any resource
  # within the API Gateway REST API.
  source_arn = "${aws_api_gateway_rest_api.this.execution_arn}/*/*"
}

# We use this module to add enable CORS for our resources
module "cors" {
  source  = "squidfunk/api-gateway-enable-cors/aws"
  version = "0.3.1"

  api_id          = aws_api_gateway_rest_api.this.id
  api_resource_id = aws_api_gateway_resource.order.id
}
