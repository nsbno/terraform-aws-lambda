variable "service_name" {
  description = "The name of the service. A group of function names can be part of the same service"

  type = string
}

variable "component_name" {
  description = "The name of the component. Will be appended to the service_name if used"

  default = null
  type    = string
}

variable "alias_name" {
  description = "The name of the alias to create for the Lambda function"
  type        = string
  default     = "active"
}

variable "description" {
  description = "The description of the Lambda function"
  type        = string
  default     = null
}

variable "aws_region" {
  description = "The AWS region to deploy the Lambda function in."
  type        = string
  default     = "eu-west-1"
}

variable "publish" {
  description = "Publish the Lambda function version"
  type        = bool
  default     = true
}

variable "artifact_type" {
  description = "Where the artifact to deploy is stored. Valid values are 's3' or 'ecr'"

  type = string

  validation {
    condition     = contains(["s3", "ecr"], var.artifact_type)
    error_message = "Artifact type must be one of 's3' or 'ecr'."
  }
}

variable "artifact" {
  description = "The Lambda artifact to deploy."
  type = object({
    git_sha            = string           # S3 file name
    s3_bucket_name     = optional(string) # S3 bucket name
    s3_object_path     = optional(string) # S3 object key (infrademo-service/1234567890abcdef.zip)
    s3_object_version  = optional(string) # S3 object version
    ecr_repository_uri = optional(string) # ECR Repository URI
  })

  validation {
    condition     = var.artifact != null
    error_message = "A valid `vy_lambda_artifact` data source must be provided"
  }
}

variable "architecture" {
  description = "Architecture the lambda is compatible with. Valid values are \"x86_64\" or \"arm64\""

  type    = string
  default = "x86_64"
}

variable "runtime" {
  description = "The runtime to use for the lambda function"

  type    = string
  default = null
}

variable "handler" {
  description = "The handler to use for the lambda function"

  type    = string
  default = null
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

variable "log_format" {
  description = "The format of the logs. Can be either `Text` or `JSON`. Defaults to `Text`."
  type        = string
  default     = "Text"

  validation {
    condition     = contains(["Text", "JSON"], var.log_format)
    error_message = "Log format must be one of `Text` or `JSON`."
  }
}

# DATADOG
variable "enable_datadog" {
  description = "Enable Datadog Lambda Extension"

  type    = bool
  default = false
}

variable "custom_datadog_tags" {
  description = "Custom tags to add to the Datadog Lambda Extension. Format: `key:value,key2:value2`"

  type    = string
  default = null
}

variable "datadog_extension_layer_version" {
  description = "Version for the Datadog Extension Layer"
  type        = number
  default     = 90
}

variable "datadog_java_layer_version" {
  description = "Version for the Datadog Java Layer"
  type        = number
  default     = 24
}

variable "datadog_node_layer_version" {
  description = "Version for the Datadog Node Layer"
  type        = number
  default     = 131
}

variable "datadog_python_layer_version" {
  description = "Version for the Datadog Python Layer"
  type        = number
  default     = 119
}

variable "datadog_options" {
  description = "Additional Datadog configuration options"
  type = object({
    profiling_enabled       = optional(bool)
    trace_enabled           = optional(bool)
    logs_injection          = optional(bool)
    merge_xray_traces       = optional(bool)
    serverless_logs_enabled = optional(bool)
    capture_lambda_payload  = optional(bool)
  })
  default = {
    profiling_enabled       = false
    trace_enabled           = true
    logs_injection          = true
    merge_xray_traces       = false
    serverless_logs_enabled = true
    capture_lambda_payload  = false
  }
}

variable "datadog_api_key_secret_arn" {
  description = "ARN of the Datadog API Key secret in AWS Secrets Manager"
  type        = string
  default     = null

  validation {
    condition     = var.datadog_api_key_secret_arn == null || can(regex("^arn:aws:secretsmanager:[a-z0-9-]+:[0-9]{12}:secret:[a-zA-Z0-9/_+=.@-]+$", var.datadog_api_key_secret_arn))
    error_message = "Datadog API Key must be a valid ARN of a secret in AWS Secrets Manager."
  }
}

variable "team_name_override" {
  description = "Override the team name tag for Datadog. If set, this will override the value from the SSM parameter."
  type        = string
  default     = null
}
