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

  layers = var.layers

  publish = true

  tracing_config {
    mode = var.x_ray_mode
  }

  vpc_config {
    subnet_ids         = var.subnet_ids
    security_group_ids = var.security_group_ids
  }

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
  policy = data.aws_iam_policy_document.allow_logging.json
}

data "aws_iam_policy_document" "allow_x_ray" {
  statement {
    effect = "Allow"

    actions = [
      "xray:PutTraceSegments",
      "xray:PutTelemetryRecords",
      "xray:GetSamplingRules",
      "xray:GetSamplingTargets",
      "xray:GetSamplingStatisticSummaries"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "allow_tracing" {
  role   = aws_iam_role.this.id
  policy = data.aws_iam_policy_document.allow_x_ray.json
}

resource "aws_appautoscaling_target" "this" {
  count = var.provisioned_concurrency_capacity != null ? 1 : 0

  resource_id = "function:${aws_lambda_function.this.function_name}:${aws_lambda_function.this.version}"

  service_namespace  = "lambda"
  scalable_dimension = "lambda:function:ProvisionedConcurrency"

  min_capacity = var.provisioned_concurrency_capacity
  max_capacity = var.provisioned_concurrency_scale_to_capacity == null ? var.provisioned_concurrency_capacity : var.provisioned_concurrency_scale_to_capacity
}

resource "aws_appautoscaling_policy" "this" {
  count = var.provisioned_concurrency_capacity != null ? 1 : 0

  name               = "ScaleOut"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.this[0].resource_id
  scalable_dimension = aws_appautoscaling_target.this[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.this[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "LambdaProvisionedConcurrencyUtilization"
    }

    target_value = var.provisioned_concurrency_target_utilization
  }
}
