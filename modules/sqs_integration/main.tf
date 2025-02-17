resource "aws_lambda_event_source_mapping" "receive_amount_of_developers" {
  function_name           = var.lambda.function_name
  event_source_arn        = var.queue_arn
  function_response_types = ["ReportBatchItemFailures"]
  batch_size              = var.batch_size

  dynamic "scaling_config" {
    for_each = var.maximum_concurrency != null ? [true] : []
    content {
      maximum_concurrency = var.maximum_concurrency
    }
  }
}

data "aws_iam_policy_document" "this" {
  statement {
    effect = "Allow"

    resources = [
      var.queue_arn
    ]

    actions = [
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes"
    ]
  }
}

resource "aws_iam_role_policy" "this" {
  role   = var.lambda.role_name
  policy = data.aws_iam_policy_document.this.json
}
