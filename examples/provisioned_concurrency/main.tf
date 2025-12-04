data "vy_lambda_artifact" "user_service" {
  github_repository_name = "terraform-aws-lambda"

  # Used for monorepos. The directory where the Lambda function code is relative to root, e.g. "services/user-service".
  # working_directory      = "services/user-service"
}

module "lambda" {
  source = "../../"

  service_name = "user-service"

  artifact_type = "s3"
  artifact      = data.vy_lambda_artifact.user_service

  runtime = "python3.11"
  handler = "handler.main"

  provisioned_concurrency = {
    minimum_capacity = 0
    maximum_capacity = 4

    schedules = [
      # Always have capacity during work hours
      {
        timezone = "Europe/Oslo"
        schedule = "cron(* 6-18 ? * MON-FRI *)"

        minimum_capacity = 1
      },
    ]
  }
}
