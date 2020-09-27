# TODO
provider "aws" {
  shared_credentials_file = ""
  profile                 = ""
  region                  = "eu-central-1"
}

resource "aws_s3_bucket" "frontend" {}
