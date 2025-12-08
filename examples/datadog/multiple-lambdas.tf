locals {
  service_name_multiple_example = "user-service"
}

# Remember to add: https://github.com/nsbno/terraform-datadog-provider-setup
module "datadog_service_multiple_example" {
  # Find newest version here: https://github.com/nsbno/terraform-datadog-service/releases
  source = "github.com/nsbno/terraform-datadog-service?ref=0.1.0"

  service_name = local.service_name_multiple_example
  display_name = "Infrademo - User Service"

  github_url    = "https://github.com/nsbno/terraform-aws-lambda"
  support_email = "teaminfra@vy.no"
  slack_url     = "https://nsb-utvikling.slack.com/archives/CSXU1BBA6"
}

data "vy_lambda_artifact" "user_service_multiple_example" {
  github_repository_name = "infrademo-demo-app"

  # Used for monorepos. The directory where the Lambda function code is relative to root, e.g. "services/user-service".
  # working_directory      = "services/user-service"
}

module "get-lambda" {
  source = "../../"

  enable_datadog = true
  service_name   = local.service_name_multiple_example
  component_name = "get-user"

  artifact_type = "s3"
  artifact      = data.vy_lambda_artifact.user_service_multiple_example

  runtime = "python3.12"
  handler = "handler.main"
}

module "put-lambda" {
  source = "../../"

  enable_datadog = true
  service_name   = local.service_name_multiple_example
  component_name = "put-user"

  artifact_type = "s3"
  artifact      = data.vy_lambda_artifact.user_service_multiple_example

  runtime = "python3.12"
  handler = "handler.main"
}
