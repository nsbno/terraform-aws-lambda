data "vy_artifact_version" "this" {
  application = "user-service"
}

module "lambda" {
  source = "../../"

  name = "get-users"

  artifact_type = "s3"
  artifact      = data.vy_artifact_version.this

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
