provider "aws" {
  shared_credentials_file = "../aws-credentials"
  profile = "aws-training"
  region = "eu-central-1"

  version = "~> 3.8.0"
}

resource "aws_s3_bucket" "frontend" {

  bucket = "ahs-shop"
  acl    = "public-read"
  policy = file("policy.json")

  website {
    index_document = "index.html"
    error_document = "error.html"
  }
}

resource "aws_s3_bucket_object" "data" {
  bucket = aws_s3_bucket.frontend.id

  for_each = fileset("../../serverless/www", "**")
  key    = each.value
  source = "../../serverless/www/${each.value}"
  content_type = "text/html"
}
