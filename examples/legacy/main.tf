# Old vy provider, using CircleCI build pipeline
data "vy_artifact_version" "user_service" {
  application = "user-service"
}

module "lambda" {
  source = "../../"

  service_name  = "user-service"
  artifact_type = "s3"
  artifact      = data.vy_artifact_version.user_service

  runtime = "python3.12"
  handler = "handler.main"
}
