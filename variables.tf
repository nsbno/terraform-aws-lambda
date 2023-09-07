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
