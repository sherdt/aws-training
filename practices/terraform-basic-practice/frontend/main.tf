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

  version = "~> 3.8.0"
}

resource "aws_s3_bucket" "frontend" {

  bucket = "ahs-${var.stage}-shop"
  acl    = "public-read"
  policy = templatefile("policy.json", {
    stage = var.stage
  })

  website {
    index_document = "index.html"
    error_document = "error.html"
  }

  tags = {
    team = var.team
  }
}

resource "aws_s3_bucket_object" "data" {
  bucket = aws_s3_bucket.frontend.id

  for_each = fileset("../../serverless/www", "**")
  key    = each.value
  source = "../../serverless/www/${each.value}"
  content_type = "text/html"
}
