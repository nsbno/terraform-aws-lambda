output "lambda_arn" {
  value = aws_lambda_function.this.qualified_arn
}

output "invoke_arn" {
  value = aws_lambda_function.this.qualified_invoke_arn
}

output "function_name" {
  value = aws_lambda_function.this.function_name
}

output "role_arn" {
  value = aws_iam_role.this.arn
}

output "role_name" {
  value = aws_iam_role.this.name
}
