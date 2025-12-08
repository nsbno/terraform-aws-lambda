# Using GitHub Actions based pipeline that builds and uploads the Lambda artifact to S3.
# https://github.com/nsbno/platform-actions

data "vy_lambda_artifact" "user_service" {
  # Replace with your service GitHub repository name
  github_repository_name = "infrademo-demo-app"
}

module "s3_lambda" {
  source = "../../"

  service_name = "user-service"

  artifact_type = "s3"
  artifact      = data.vy_lambda_artifact.user_service

  runtime = "python3.12"
  handler = "handler.main"

  memory = 256
}
