output "bucket_created" {
  value = aws_s3_bucket.terraform_state
}
output "dynamo_created" {
  value = aws_dynamodb_table.terraform_locks
}

