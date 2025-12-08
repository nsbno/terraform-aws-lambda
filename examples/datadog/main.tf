locals {
  service_name = "user-service"
}

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
  # Replace with your service GitHub repository name
  github_repository_name = "infrademo-demo-app"
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
