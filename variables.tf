variable "name" {
  description = "The name of the lambda function"

  type = string
}

variable "datadog_service_name" {
  description = "The name of the service. A group of function names can be part of the same service"

  default = null
  type    = string
}

variable "custom_datadog_tags" {
  description = "Custom tags to add to the Datadog Lambda Extension. Format: `key:value,key2:value2`"

  type    = string
  default = null
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

variable "runtime" {
  description = "The runtime to use for the lambda function"

  type = string
}

variable "architectures" {
  description = "The architectures to use for the lambda function"

  type    = list(string)
  default = ["x86_64"]
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

# DATADOG

variable "datadog_extension_layer_version" {
  description = "Version for the Datadog Extension Layer"
  type        = number
  default     = 63
}

variable "datadog_java_layer_version" {
  description = "Version for the Datadog Java Layer"
  type        = number
  default     = 15
}

variable "datadog_node_layer_version" {
  description = "Version for the Datadog Node Layer"
  type        = number
  default     = 115
}

variable "datadog_python_layer_version" {
  description = "Version for the Datadog Python Layer"
  type        = number
  default     = 98
}
