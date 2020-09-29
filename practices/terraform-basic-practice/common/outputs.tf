output "db-sg-id" {
  value = aws_security_group.db-sg.id
}

output "lambda-sg-id" {
  value = aws_security_group.lambda-sg.id
}

output "allow-all-sg-id" {
  value = aws_security_group.allow_all.id
}

output "ahs-lambda-eni-policy-arn" {
  value = aws_iam_policy.lambda_eni.arn
}

output "ahs-lambda-logging-policy-arn" {
  value = aws_iam_policy.lambda_logging.arn
}

output "ahs-lambda-iam-role" {
  value = aws_iam_role.iam-role
}