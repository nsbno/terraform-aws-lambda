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
