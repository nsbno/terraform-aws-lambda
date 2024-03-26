output "lambda_arn" {
  value = aws_lambda_alias.this.arn
}

output "invoke_arn" {
  value = aws_lambda_alias.this.invoke_arn
}

output "function_name" {
  value = aws_lambda_alias.this.function_name
}

output "function_qualifier" {
  value = aws_lambda_alias.this.name
}

output "role_arn" {
  value = aws_iam_role.this.arn
}

output "role_name" {
  value = aws_iam_role.this.name
}
