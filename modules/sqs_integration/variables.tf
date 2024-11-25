variable "lambda" {
  description = "The output of the main lambda module"

  type = object({
    lambda_arn         = string
    invoke_arn         = string
    function_name      = string
    function_qualifier = string
    role_arn           = string
    role_name          = string
  })
}

variable "queue_arn" {
  description = "ARN of the SQS queue"
  type        = string
}

variable "batch_size" {
  description = "The maximum number of events to retrieve in a single batch in the lambda"
  type        = number
  default     = null
}
