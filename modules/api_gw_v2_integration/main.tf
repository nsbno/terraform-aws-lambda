resource "aws_apigatewayv2_integration" "this" {
  api_id           = var.api_id
  integration_type = "AWS_PROXY"

  integration_method = "POST"
  integration_uri    = var.lambda.invoke_arn

  payload_format_version = var.payload_format_version
}

resource "aws_lambda_permission" "this" {
  statement_id = "AllowExecutionFromAPIGateway"

  action    = "lambda:InvokeFunction"
  principal = "apigateway.amazonaws.com"

  function_name = var.lambda.function_name
  qualifier     = var.lambda.function_qualifier

  source_arn = "${var.api_execution_arn}/*/*"
}
