resource "aws_lambda_event_source_mapping" "receive_amount_of_developers" {
  function_name           = var.lambda.lambda_arn
  event_source_arn        = var.queue_arn
  function_response_types = ["ReportBatchItemFailures"]
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
  role   = var.lambda.role_arn
  policy = data.aws_iam_policy_document.this.json
}
