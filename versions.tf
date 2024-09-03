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

provider "datadog" {
  api_key = data.aws_secretsmanager_secret_version.datadog_api_key.secret_string
  app_key = data.aws_secretsmanager_secret_version.datadog_app_key.secret_string

  api_url = "https://api.datadoghq.eu/"
}
