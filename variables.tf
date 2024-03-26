variable "name" {
  description = "The name of the lambda function"

  type = string
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

variable "provisioned_concurrency" {
  description = "Settings for provisioned concurrency"

  nullable = true
  type     = object({
    minimum_capacity   = number
    maximum_capacity   = number
    target_utilization = optional(number, 0.8)
    scale_in_cooldown  = optional(number, 600)
    scale_out_cooldown = optional(number, 120)
  })

  default = null
}
