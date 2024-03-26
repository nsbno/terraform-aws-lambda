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

  lambda = module.lambda

  queue_arn = module.request_queue.queue_arn
}

module "api_gateway" {
  source = "../../modules/api_gw_v2_integration"

  lambda                 = module.lambda

  payload_format_version = "2.0"

  api_execution_arn      = local.api_execution_arn
  api_id                 = local.api_id
}
