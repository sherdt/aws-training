terraform {
  required_version = "~> 0.12"
  required_providers {
    aws = "~> 2.47"
    null = "~> 2.1"
  }
  backend "s3" {
    bucket         = "terraform-statemanager-store-123812902"
    key            = "live/prodyna-aws-training/prod/services/frontend/terraform.tfstate"
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

resource "aws_s3_bucket" "frontend" {
  bucket = local.bucketName
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

  acl = "public-read"

  website {
    index_document = "index.html"
    error_document = "error.html"
  }

  tags = local.default_tags
}

# Upload S3 files
resource "aws_s3_bucket_object" "app" {
  for_each = fileset("${path.module}/app", "**")

  bucket = aws_s3_bucket.frontend.bucket
  key    = each.value
  source = "${path.module}/app/${each.value}"
  content_type = "text/html"

  acl = "public-read"

  tags = local.default_tags
}
