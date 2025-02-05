variable "name" {
  description = "The name of the lambda function"

  type = string
}

variable "description" {
  description = "The description of the Lambda function"
  type        = string
  default     = null
}

variable "artifact_type" {
  description = "The type of artifact to deploy"

  type = string

  validation {
    condition     = contains(["s3", "ecr"], var.artifact_type)
    error_message = "Artifact type must be one of `s3` or `ecr`."
  }
}

variable "artifact" {
  type = object({
    store   = string
    path    = string
    version = string
  })
}

variable "architecture" {
  description = "Architecture the lambda is compatible with. Valid values are \"x86_64\" or \"arm64\""

  type    = string
  default = "x86_64"
}

variable "runtime" {
  description = "The runtime to use for the lambda function"

  type = string
}

variable "handler" {
  description = "The handler to use for the lambda function"

  type = string
}

variable "timeout" {
  description = "Max runtime in seconds for the lambda function"

  type    = number
  default = 120
}

variable "environment_variables" {
  description = "Environment variables to set for the lambda function"

  type    = map(string)
  default = {}
}

variable "memory" {
  description = "The amount of memory to allocate to the lambda function"

  type    = number
  default = 128
}

variable "layers" {
  description = "List of lambda layer version ARNs (maximum of 5) to attach to your lambda function"

  type    = list(string)
  default = []
}

variable "subnet_ids" {
  description = "List of subnet IDs to place the lambda function within. Part of VPC config"

  type    = list(string)
  default = []
}

variable "security_group_ids" {
  description = "List of security group IDs to place the lambda function within. Part of VPC config"

  type    = list(string)
  default = []
}

variable "x_ray_mode" {
  description = "The tracing mode for AWS X-Ray"

  type    = string
  default = "PassThrough"
}

variable "snap_start" {
  description = "Enable or disable snap start for the lambda function"

  type    = bool
  default = false
}

variable "provisioned_concurrency" {
  description = "Settings for provisioned concurrency"

  nullable = true

  type = object({
    minimum_capacity   = number
    maximum_capacity   = number
    target_utilization = optional(number, 0.8)
    scale_in_cooldown  = optional(number, 600)
    scale_out_cooldown = optional(number, 120)
    schedules = optional(list(object({
      timezone = string
      schedule = string

      minimum_capacity = optional(number, null)
      maximum_capacity = optional(number, null)
    })))
  })

  default = null
}

variable "schedule" {
  description = "Make the lambda run on a schedule. For example, cron(0 20 * * ? *) or rate(5 minutes)"
  type = object({
    expression = string
  })
  default = null
}

variable "log_retention_in_days" {
  description = "Specifies the number of days you want to retain log events in the specified log group. Possible values are: 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, and 3653."
  type        = number
  default     = 30
}

variable "reserved_concurrent_executions" {
  description = "The amount of reserved concurrent executions for this Lambda Function. A value of 0 disables Lambda Function from being triggered and -1 removes any concurrency limitations. Defaults to Unreserved Concurrency Limits -1."
  type        = number
  default     = null
}

variable "enable_json_log_level_metric_filter" {
  description = "Enable JSON log level metric filter. Creates a metric on log levels from the Lambda function. The logs must be in JSON format, and must have a field named 'level'."
  type        = bool
  default     = false
}

variable "enable_insights" {
  description = "Enable Lambda Insights for more detailed monitoring"
  type        = bool
  default     = false
}

variable "log_group_name" {
  description = "Override default log group name, if not set a default name will be used from the lambda function name"
  type        = string
  default     = null
}
