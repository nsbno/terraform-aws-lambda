terraform {
  required_version = ">= 1.3.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.26.0"
    }
    datadog = {
      source  = "DataDog/datadog"
      version = ">= 3.40.0"
    }
  }
}
