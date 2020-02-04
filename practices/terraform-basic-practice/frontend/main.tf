provider "aws" {
  region     = "eu-central-1"
  access_key = var.aws_credentials.access_key # TODO
  secret_key = var.aws_credentials.secret_key # TODO
}

resource "aws_s3_bucket" "frontend" {}
