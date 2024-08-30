data "aws_region" "current" {}

# Locals from datadog module: https://github.com/DataDog/terraform-aws-lambda-datadog/blob/main/main.tf
locals {
  architecture_layer_suffix_map = {
    x86_64 = "",
    arm64  = "-ARM"
  }
  runtime_base = regex("[a-z]+", var.runtime)
  runtime_base_environment_variable_map = {
    java = {
      AWS_LAMBDA_EXEC_WRAPPER = "/opt/datadog_wrapper"
    }
    nodejs = {
      DD_LAMBDA_HANDLER = var.handler
    }
    python = {
      DD_LAMBDA_HANDLER = var.handler
    }
  }
  runtime_base_handler_map = {
    java   = var.handler
    nodejs = "/opt/nodejs/node_modules/datadog-lambda-js/handler.handler"
    python = "datadog_lambda.handler.handler"
  }
  runtime_base_layer_version_map = {
    java   = var.datadog_java_layer_version
    nodejs = var.datadog_node_layer_version
    python = var.datadog_python_layer_version
  }
  runtime_layer_map = {
    "java8.al2"  = "dd-trace-java"
    "java11"     = "dd-trace-java"
    "java17"     = "dd-trace-java"
    "java21"     = "dd-trace-java"
    "nodejs16.x" = "Datadog-Node16-x"
    "nodejs18.x" = "Datadog-Node18-x"
    "nodejs20.x" = "Datadog-Node20-x"
    "python3.8"  = "Datadog-Python38"
    "python3.9"  = "Datadog-Python39"
    "python3.10" = "Datadog-Python310"
    "python3.11" = "Datadog-Python311"
    "python3.12" = "Datadog-Python312"
  }
}

locals {
  datadog_extension_layer_arn    = "${local.datadog_layer_name_base}:Datadog-Extension${local.datadog_extension_layer_suffix}:${var.datadog_extension_layer_version}"
  datadog_extension_layer_suffix = local.datadog_layer_suffix

  datadog_lambda_layer_arn    = "${local.datadog_layer_name_base}:${local.datadog_lambda_layer_runtime}${local.datadog_lambda_layer_suffix}:${local.datadog_lambda_layer_version}"
  datadog_lambda_layer_suffix = contains(["java", "nodejs"], local.runtime_base) ? "" : local.datadog_layer_suffix
  # java and nodejs don't have separate layers for ARM
  datadog_lambda_layer_runtime = lookup(local.runtime_layer_map, var.runtime, "")
  datadog_lambda_layer_version = lookup(local.runtime_base_layer_version_map, local.runtime_base, "")

  datadog_account_id      = "464622532012"
  datadog_layer_name_base = "arn:aws:lambda:${data.aws_region.current.name}:${local.datadog_account_id}:layer"
  datadog_layer_suffix    = lookup(local.architecture_layer_suffix_map, var.architectures[0])

  environment_variables = {
    common = {
      DD_CAPTURE_LAMBDA_PAYLOAD  = "false"
      DD_LOGS_INJECTION          = "false"
      DD_MERGE_XRAY_TRACES       = "false"
      DD_SERVERLESS_LOGS_ENABLED = "true"
      DD_EXTENSION_VERSION       = "next"
      DD_SERVICE                 = var.name
      DD_API_KEY_SECRET_ARN      = data.aws_secretsmanager_secret.datadog_api_key.arn
      DD_SITE                    = "datadoghq.eu"
      DD_TRACE_ENABLED           = "true"
    }
    runtime = lookup(local.runtime_base_environment_variable_map, local.runtime_base, {})
  }

  handler = lookup(local.runtime_base_handler_map, local.runtime_base, var.handler)

  layers = {
    extension = [local.datadog_extension_layer_arn]
    lambda    = local.datadog_lambda_layer_runtime == "" ? [] : [local.datadog_lambda_layer_arn]
  }
}

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
      data.aws_secretsmanager_secret.datadog_api_key.arn
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

  package_type = var.artifact_type == "s3" ? "Zip" : "Image"

  s3_bucket         = var.artifact_type == "s3" ? var.artifact.store : null
  s3_key            = var.artifact_type == "s3" ? var.artifact.path : null
  s3_object_version = var.artifact_type == "s3" ? var.artifact.version : null
  image_uri         = var.artifact_type == "ecr" ? "${var.artifact.store}/${var.artifact.path}@${var.artifact.version}" : null

  timeout = var.timeout

  runtime       = var.artifact_type == "s3" ? var.runtime : null
  handler       = local.handler
  architectures = var.architectures

  memory_size = var.memory

  role = aws_iam_role.this.arn

  layers = concat(var.layers, [
    local.layers.extension,
    local.layers.lambda
  ])

  publish = true

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
    variables = var.environment_variables
  }
}

resource "aws_lambda_alias" "this" {
  name = "active"

  function_name    = aws_lambda_function.this.function_name
  function_version = aws_lambda_function.this.version
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
