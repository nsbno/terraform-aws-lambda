# Using GitHub Actions based pipeline that builds and uploads the Lambda artifact to S3.
# https://github.com/nsbno/platform-actions

data "vy_lambda_artifact" "ecr_user_service" {
  github_repository_name = "terraform-aws-lambda"

  # The ECR Repository name where the Lambda image is pushed.
  ecr_repository_name = "user-service-repo"
}

module "ecr_lambda" {
  source = "../../"

  service_name = "user-service"

  artifact_type = "ecr"
  artifact      = data.vy_lambda_artifact.ecr_user_service

  memory = 256
}
