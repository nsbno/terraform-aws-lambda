module "account_metadata" {
  source = "github.com/nsbno/terraform-aws-account-metadata?ref=0.2.0"

  dns           = false
  load_balancer = false
}

data "aws_region" "current" {}

data "aws_secretsmanager_secret" "datadog_api_key" {
  arn = "arn:aws:secretsmanager:eu-west-1:727646359971:secret:datadog_agent_api_key"
}

data "aws_iam_policy_document" "secrets_manager" {
  statement {
    effect = "Allow"

    actions = [
      "secretsmanager:GetSecretValue",
    ]

    resources = [
      data.aws_secretsmanager_secret.datadog_api_key.arn,
    ]
  }
  statement {
    effect = "Allow"

    actions = [
      "kms:Decrypt"
    ]

    resources = [
      "arn:aws:kms:eu-west-1:727646359971:key/1bfdf87f-a69c-41f8-929a-2a491fc64f69",
    ]
  }
}

resource "aws_iam_role_policy" "secrets_manager" {
  role   = aws_iam_role.this.id
  policy = data.aws_iam_policy_document.secrets_manager.json
}

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
  description   = var.description

  package_type = var.artifact_type == "s3" ? "Zip" : "Image"

  s3_bucket         = var.artifact_type == "s3" ? var.artifact.store : null
  s3_key            = var.artifact_type == "s3" ? var.artifact.path : null
  s3_object_version = var.artifact_type == "s3" ? var.artifact.version : null
  image_uri         = var.artifact_type == "ecr" ? "${var.artifact.store}/${var.artifact.path}@${var.artifact.version}" : null

  timeout = var.timeout

  runtime = var.artifact_type == "s3" ? var.runtime : null
  handler = local.handler

  architectures = [var.architecture]

  memory_size = var.memory

  role = aws_iam_role.this.arn

  layers = var.enable_insights ? concat(
    local.lambda_layers,
    ["arn:aws:lambda:eu-west-1:580247275435:layer:LambdaInsightsExtension:33"]
  ) : local.lambda_layers

  publish = true

  reserved_concurrent_executions = var.reserved_concurrent_executions

  dynamic "snap_start" {
    for_each = var.snap_start ? [{}] : []

    content {
      apply_on = "PublishedVersions"
    }
  }

  tracing_config {
    mode = var.x_ray_mode
  }

  vpc_config {
    subnet_ids         = var.subnet_ids
    security_group_ids = var.security_group_ids
  }

  environment {
    variables = merge(var.environment_variables, local.environment_variables.common, local.environment_variables.runtime)
  }
}

data "aws_iam_policy_document" "vpc_access_permissions" {
  statement {
    effect = "Allow"
    actions = [
      "ec2:CreateNetworkInterface",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DescribeSubnets",
      "ec2:DeleteNetworkInterface",
      "ec2:AssignPrivateIpAddresses",
      "ec2:UnassignPrivateIpAddresses"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSubnets",
      "ec2:DescribeVpcs"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "vpc_access_permissions_attachment" {
  role   = aws_iam_role.this.name
  policy = data.aws_iam_policy_document.vpc_access_permissions.json
}

resource "aws_lambda_alias" "this" {
  name = "active"

  function_name    = aws_lambda_function.this.function_name
  function_version = aws_lambda_function.this.version
}

resource "aws_cloudwatch_log_group" "this" {
  name              = var.log_group_name != null ? "/aws/lambda/${var.log_group_name}" : "/aws/lambda/${aws_lambda_function.this.function_name}"
  retention_in_days = var.log_retention_in_days
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

resource "aws_iam_role_policy_attachment" "insights_policy" {
  count      = var.enable_insights ? 1 : 0
  role       = aws_iam_role.this.id
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLambdaInsightsExecutionRolePolicy"
}

resource "aws_appautoscaling_target" "this" {
  count = var.provisioned_concurrency != null ? 1 : 0

  resource_id = "function:${aws_lambda_alias.this.function_name}:${aws_lambda_alias.this.name}"

  service_namespace  = "lambda"
  scalable_dimension = "lambda:function:ProvisionedConcurrency"

  min_capacity = var.provisioned_concurrency.minimum_capacity
  max_capacity = var.provisioned_concurrency.maximum_capacity
}

resource "aws_appautoscaling_policy" "this" {
  count = var.provisioned_concurrency != null ? 1 : 0

  name        = "${var.name}-lambda-auto-scaling"
  policy_type = "TargetTrackingScaling"

  resource_id        = aws_appautoscaling_target.this[0].resource_id
  scalable_dimension = aws_appautoscaling_target.this[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.this[0].service_namespace

  target_tracking_scaling_policy_configuration {
    target_value = var.provisioned_concurrency.target_utilization

    scale_in_cooldown  = var.provisioned_concurrency.scale_in_cooldown
    scale_out_cooldown = var.provisioned_concurrency.scale_out_cooldown

    # A custom metric specification using LambdaProvisionedConcurrencyUtilization
    # that fills in missing data as zero
    customized_metric_specification {
      metrics {
        label = "Provisioned Concurrency Utilization"
        id    = "m1"

        return_data = false

        metric_stat {
          stat = "Average"

          metric {
            metric_name = "ProvisionedConcurrencyUtilization"
            namespace   = "AWS/Lambda"

            dimensions {
              name  = "FunctionName"
              value = aws_lambda_function.this.function_name
            }

            dimensions {
              name  = "Resource"
              value = "${aws_lambda_function.this.function_name}:${aws_lambda_function.this.version}"
            }
          }
        }
      }

      metrics {
        label = "Provisioned Concurrency Utilization with missing values"
        id    = "e1"

        expression = "FILL(m1, 0)"

        return_data = true
      }
    }
  }
}

resource "aws_appautoscaling_scheduled_action" "this" {
  for_each = var.provisioned_concurrency != null ? {
    for v in var.provisioned_concurrency.schedules : v.schedule => v
  } : {}

  name               = "${var.name}-lambda-scheduled-scaling"
  resource_id        = aws_appautoscaling_target.this[0].resource_id
  scalable_dimension = aws_appautoscaling_target.this[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.this[0].service_namespace

  timezone = each.value.timezone
  schedule = each.value.schedule

  scalable_target_action {
    min_capacity = each.value.minimum_capacity
    max_capacity = each.value.maximum_capacity
  }
}

/*
* == Scheduling
 */

resource "aws_scheduler_schedule" "schedule" {
  count       = var.schedule != null ? 1 : 0
  name        = "${aws_lambda_function.this.function_name}-schedule"
  description = "Schedule for Lambda Function ${aws_lambda_function.this.function_name}"
  group_name  = "default"

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression = var.schedule.expression

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

/*
* == End Scheduling
 */

// Metric filter on JSON log levels from the Lambda function
resource "aws_cloudwatch_log_metric_filter" "lambda_log_events" {
  count          = var.enable_json_log_level_metric_filter ? 1 : 0
  name           = "${aws_lambda_function.this.function_name}-log-levels"
  pattern        = "{ $.level = * }"
  log_group_name = aws_cloudwatch_log_group.this.name

  metric_transformation {
    name      = "LambdaLogLevels"
    namespace = "Lambda/${aws_lambda_function.this.function_name}"
    value     = "1"
    unit      = "Count"
    dimensions = {
      level = "$.level"
    }
  }
}
