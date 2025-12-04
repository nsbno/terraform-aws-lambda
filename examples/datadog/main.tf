locals {
  service_name = "user-service"
}

# Remember to add: https://github.com/nsbno/terraform-datadog-provider-setup

module "datadog_service" {
  # Find newest version here: https://github.com/nsbno/terraform-datadog-service/releases
  source = "github.com/nsbno/terraform-datadog-service?ref=0.1.0"

  service_name = local.service_name
  display_name = "Infrademo - User Service"

  github_url    = "https://github.com/nsbno/terraform-aws-lambda"
  support_email = "teaminfra@vy.no"
  slack_url     = "https://nsb-utvikling.slack.com/archives/CSXU1BBA6"
}

data "vy_lambda_artifact" "user_service" {
  github_repository_name = "terraform-aws-lambda"

  # Used for monorepos. The directory where the Lambda function code is relative to root, e.g. "services/user-service".
  # working_directory      = "services/user-service"
}

module "lambda" {
  source = "../../"

  enable_datadog = true
  service_name   = module.datadog_service.service_name

  artifact_type = "s3"
  artifact      = data.vy_lambda_artifact.user_service

  runtime = "python3.12"
  handler = "handler.main"
}
