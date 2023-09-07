variable "lambda_arn" {
  description = "ARN of the Lambda function"
  type        = string
}

variable "lambda_role_arn" {
  description = "ARN of the Lambda function's role"
  type        = string
}

variable "queue_arn" {
  description = "ARN of the SQS queue"
  type        = string
}
