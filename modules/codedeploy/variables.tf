variable "function_name" {
  description = "The name of the Lambda function"
  type        = string
}

variable "lambda_ecr_image_base" {
  description = "The ECR Image Base of the Lambda image"
  type        = string
}

variable "artifact" {
  description = "The artifact to deploy"
  type = object({
    store   = string
    path    = string
    version = string
  })
}

variable "deployment_config_name" {
  description = "The deployment config name"
  type        = string
  default     = "CodeDeployDefault.LambdaAllAtOnce"
}

variable "deployment_group_name" {
  description = "The deployment group name"
  type        = string
}

variable "rollback_window_in_minutes" {
  description = "The rollback window in minutes"
  type        = number
  default     = 0
}

