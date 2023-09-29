data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "this" {
  name = "${var.name}-lambda"

  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

resource "aws_lambda_function" "this" {
  function_name = var.name

  package_type = var.artifact_type == "s3" ? "Zip" : "Image"

  s3_bucket         = var.artifact_type == "s3" ? var.artifact.store : null
  s3_key            = var.artifact_type == "s3" ? var.artifact.path : null
  s3_object_version = var.artifact_type == "s3" ? var.artifact.version : null
  image_uri         = var.artifact_type == "ecr" ? "${var.artifact.store}/${var.artifact.path}@${var.artifact.version}" : null

  timeout = var.timeout

  runtime = var.artifact_type == "s3" ? var.runtime : null
  handler = var.handler

  memory_size = var.memory

  role = aws_iam_role.this.arn

  environment {
    variables = var.environment_variables
  }
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/lambda/${aws_lambda_function.this.function_name}"
  retention_in_days = 30
}

data "aws_iam_policy_document" "allow_logging" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      aws_cloudwatch_log_group.this.arn,
      "${aws_cloudwatch_log_group.this.arn}:*",
    ]
  }
}

resource "aws_iam_role_policy" "allow_logging" {
  role   = aws_iam_role.this.id
  policy = data.aws_iam_policy_document.assume_role_policy.json
}
