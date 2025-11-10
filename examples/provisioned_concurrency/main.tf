module "lambda" {
  source = "../../"

  service_name = "user-service"

  artifact_type          = "s3"
  service_account_id     = "471635792310"
  github_repository_name = "infrademo-demo-app"
  # Last part of the path to the lambda function, e.g., "user-service" for "services/user-service". For monorepos
  # service_directory      = "user-service"

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
