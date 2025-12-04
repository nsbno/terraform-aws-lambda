# Using GitHub Actions based pipeline that builds and uploads the Lambda artifact to S3.
# https://github.com/nsbno/platform-actions

data "vy_lambda_artifact" "user_service" {
  github_repository_name = "terraform-aws-lambda"
  working_directory      = "services/user-service"
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
  github_repository_name = "terraform-aws-lambda"
  working_directory      = "services/order-service"
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
