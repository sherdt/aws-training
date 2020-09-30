provider "aws" {
  shared_credentials_file = "../aws-credentials"
  profile                 = "aws-training"
  region                  = "eu-central-1"

  version = "~> 3.8.0"
}

resource "aws_dynamodb_table" "lock_db" {
  name = "ahs-terraform-state-lock-table"
  hash_key = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }

  write_capacity = 5
  read_capacity = 5

  tags = {
    Name = "ahs-terraform-state-lock-table"
    team = "ahs"
  }
}

resource "aws_s3_bucket" "terraform-states" {

  bucket = "ahs-terraform-states"
  policy = file("policy.json")
  acl = "private"

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
}