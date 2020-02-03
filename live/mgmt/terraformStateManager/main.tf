terraform {
  required_version = "~> 0.12"
  required_providers {
    aws = "~> 2.47"
  }
}

provider "aws" {
  region     = "eu-central-1"
  access_key = var.aws_credentials.access_key
  secret_key = var.aws_credentials.secret_key
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = local.store_name
  versioning {
    enabled = true
  }
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = local.default_tags
}

resource "aws_dynamodb_table" "terraform_locks" {
  name         = local.lock_database_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }

  tags = local.default_tags
}
