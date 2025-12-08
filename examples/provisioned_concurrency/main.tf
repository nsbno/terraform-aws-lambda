data "vy_lambda_artifact" "user_service" {
  # Replace with your service GitHub repository name
  github_repository_name = "infrademo-demo-app"
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
