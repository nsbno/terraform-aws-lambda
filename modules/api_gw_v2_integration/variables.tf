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

variable "payload_format_version" {
    description = "The version of the API Gateway payload format"

    type = string
}

variable "api_id" {
  description = "The ID of the API Gateway"

  type = string
}

variable "api_execution_arn" {
  description = "The ARN of the API Gateway execution role"

  type = string
}
