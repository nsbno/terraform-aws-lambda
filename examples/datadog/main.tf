locals {
  application_name = "user-service"
}

data "vy_artifact_version" "this" {
  application = "user-service"
}

# Remember to add: https://github.com/nsbno/terraform-datadog-provider-setup

module "datadog_service" {
  # Find newest version here: https://github.com/nsbno/terraform-datadog-service/releases
  source = "github.com/nsbno/terraform-datadog-service?ref=x.y.z"

  service_name = local.application_name
  display_name = "Infrademo - User Service"

  github_url    = "https://github.com/nsbno/terraform-aws-lambda"
  support_email = "teaminfra@vy.no"
  slack_url     = "https://nsb-utvikling.slack.com/archives/CSXU1BBA6"
}

module "lambda" {
  source = "../../"

  enable_datadog = true
  name           = module.datadog_service.service_name

  artifact_type = "s3"
  artifact      = data.vy_artifact_version.this

  runtime = "python3.12"
  handler = "handler.main"
}
