variable "team" {
  description = "The team responsible for the service"
  type        = string
}

variable "service_name" {
  description = "The name of the service"
  type        = string
}

variable "description" {
  description = "A description of the service"
  type        = string
  default     = ""
}

variable "datadog_api_key" {
  description = "The Datadog API key"
  type        = string
}

variable "datadog_app_key" {
  description = "The Datadog application key"
  type        = string
}
