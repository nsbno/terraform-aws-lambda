# Using GitHub Actions based pipeline that builds and uploads the Lambda artifact to S3.
# https://github.com/nsbno/platform-actions

data "vy_lambda_artifact" "user_service" {
  # Replace with your service GitHub repository name
  github_repository_name = "infrademo-demo-app"
  # Used for monorepos. The directory where the Lambda function code is relative to root, e.g. "services/user-service".
  working_directory = "services/user-service"
}

module "user_service_lambda" {
  source = "../../"

  service_name = "user-service"

  artifact_type = "s3"
  artifact      = data.vy_lambda_artifact.user_service

  runtime = "python3.12"
  handler = "handler.main"

  memory = 256
}

data "vy_lambda_artifact" "order_service" {
  # Replace with your service GitHub repository name
  github_repository_name = "infrademo-demo-app"
  # Used for monorepos. The directory where the Lambda function code is relative to root, e.g. "services/user-service".
  working_directory = "services/order-service"
}

module "order_service_lambda" {
  source = "../../"

  service_name = "order-service"

  artifact_type = "s3"
  artifact      = data.vy_lambda_artifact.order_service

  runtime = "python3.12"
  handler = "handler.main"

  memory = 256
}
