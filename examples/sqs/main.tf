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
}

module "request_queue" {
  source = "github.com/nsbno/terraform-aws-queue?ref=0.0.5"

  name = "get-users"

  visibility_timeout = 30
}

module "sqs_integration" {
  source = "../../modules/sqs_integration"

  lambda_arn      = module.lambda.lambda_arn
  lambda_role_arn = module.lambda.role_arn

  queue_arn = module.request_queue.queue_arn
}
