output "invoke_arn" {
  value = aws_lambda_function.insert_object.invoke_arn
}
output "function_name" {
  value = aws_lambda_function.insert_object.function_name
}