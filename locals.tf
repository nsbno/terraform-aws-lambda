
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
  datadog_layer_suffix    = lookup(local.architecture_layer_suffix_map, var.architecture)

  combined_tags = join(",", compact([
      var.custom_datadog_tags,
      format("team:%s", data.aws_ssm_parameter.team_name.value)
  ]))

  # The account alias includes the name of the environment we are in as a suffix
  split_alias = split("-", data.aws_iam_account_alias.this.account_alias)
  environment_index = length(local.split_alias) - 1
  environment  = local.split_alias[local.environment_index]

  environment_variables = {
    common = {
      DD_CAPTURE_LAMBDA_PAYLOAD       = "false"
      DD_LOGS_INJECTION               = "false"
      DD_MERGE_XRAY_TRACES            = "true"
      DD_SERVERLESS_LOGS_ENABLED      = "true"
      DD_LOGS_CONFIG_PROCESSING_RULES = "[{ \"type\" : \"exclude_at_match\", \"name\" :\"exclude_start_and_end_logs\", \"pattern\" : \"(START|END|REPORT) RequestId\" }]"
      DD_PROFILING_ENABLED            = "true"
      DD_EXTENSION_VERSION            = "next"
      DD_SERVICE                      = var.datadog_service_name == null ? var.name : var.datadog_service_name
      DD_ENV                          = local.environment
      DD_VERSION                      = var.artifact.version
      DD_API_KEY_SECRET_ARN           = data.aws_secretsmanager_secret.datadog_api_key.arn
      DD_SITE                         = "datadoghq.eu"
      DD_TRACE_ENABLED                = "true"
      DD_TRACE_REMOVE_INTEGRATION_SERVICE_NAMES_ENABLED = "true"
      DD_TAGS                         = local.combined_tags
    }
    runtime = lookup(local.runtime_base_environment_variable_map, local.runtime_base, {})
  }

  handler = lookup(local.runtime_base_handler_map, local.runtime_base, var.handler)

  lambda_layers = var.enable_datadog ? concat(
    [local.datadog_extension_layer_arn],
    local.datadog_lambda_layer_runtime == "" ? [] : [local.datadog_lambda_layer_arn],
    var.layers
  ) : var.layers
}
