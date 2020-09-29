output "invoke_arn" {
  value = aws_lambda_function.get_objects.invoke_arn
}
output "function_name" {
  value = aws_lambda_function.get_objects.function_name
}