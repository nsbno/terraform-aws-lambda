resource "aws_scheduler_schedule" "schedule" {
  count       = var.schedule != null ? 1 : 0
  name        = "${aws_lambda_function.this.function_name}-schedule"
  description = "Schedule for Lambda Function ${aws_lambda_function.this.function_name}"
  group_name  = "default"

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression = var.schedule

  target {
    arn      = aws_lambda_function.this.qualified_arn
    role_arn = aws_iam_role.allow_scheduler_to_run_lambda[0].arn

    input = "{}"

    retry_policy {
      maximum_event_age_in_seconds = 300
      maximum_retry_attempts       = 1
    }
  }

  depends_on = [
    aws_iam_role.allow_scheduler_to_run_lambda
  ]
}

resource "aws_iam_role" "allow_scheduler_to_run_lambda" {
  count = var.schedule != null ? 1 : 0
  name  = "${aws_lambda_function.this.function_name}-schedule"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "scheduler.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "allow_scheduler_to_run_lambda" {
  count       = var.schedule != null ? 1 : 0
  name        = "${aws_lambda_function.this.function_name}-schedule"
  description = "Policy to allow scheduler to run lambda"
  policy      = data.aws_iam_policy_document.allow_scheduler_to_run_lambda.json
}

resource "aws_iam_role_policy_attachment" "allow_scheduler_to_run_lambda" {
  count      = var.schedule != null ? 1 : 0
  role       = aws_iam_role.allow_scheduler_to_run_lambda[0].name
  policy_arn = aws_iam_policy.allow_scheduler_to_run_lambda[0].arn
}

data "aws_iam_policy_document" "allow_scheduler_to_run_lambda" {
  statement {
    sid = "1"

    actions = [
      "lambda:InvokeFunction"
    ]

    resources = [
      aws_lambda_function.this.qualified_arn
    ]
  }
}
