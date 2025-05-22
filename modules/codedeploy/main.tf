## Code Deploy role
data "aws_iam_policy_document" "assume_role_code_deploy" {
  statement {
	effect = "Allow"

	principals {
	  type        = "Service"
	  identifiers = ["codedeploy.amazonaws.com"]
	}

	actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "codedeploy_role" {
  name               = "codedeploy-role-lambda"
  assume_role_policy = data.aws_iam_policy_document.assume_role_code_deploy.json
}

resource "aws_iam_role_policy_attachment" "AWSCodeDeployRole" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
  role       = aws_iam_role.codedeploy_role.name
}

resource "aws_iam_role_policy_attachment" "codedeploy_deployment_lambda" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRoleForLambdaLimited"
  role       = aws_iam_role.codedeploy_role.name
}

## Code Deploy application and deployment group

resource "aws_codedeploy_app" "this" {
  compute_platform = "Lambda"
  name             = var.function_name
}

resource "aws_codedeploy_deployment_group" "this" {
  app_name               = aws_codedeploy_app.this.name
  deployment_config_name = var.deployment_config_name
  deployment_group_name  = var.deployment_group_name
  service_role_arn       = aws_iam_role.codedeploy_role.arn

  auto_rollback_configuration {
	enabled = true
	events  = ["DEPLOYMENT_FAILURE"]
  }

  deployment_style {
	deployment_option = "WITH_TRAFFIC_CONTROL"
	deployment_type   = "BLUE_GREEN"
  }

  blue_green_deployment_config {
	deployment_ready_option {
	  action_on_timeout = "CONTINUE_DEPLOYMENT"
	}
	terminate_blue_instances_on_deployment_success {
	  action                           = "TERMINATE"
	  termination_wait_time_in_minutes = var.rollback_window_in_minutes
	}
  }
}

locals {
  ssm_parameters = {
	compute_target              = "lambda"
	codedeploy_deployment_group = aws_codedeploy_deployment_group.this.deployment_group_name
	codedeploy_application_name = aws_codedeploy_app.this.name
	lambda_function_name        = var.function_name
	lambda_s3_bucket            = var.artifact.store
	lambda_s3_folder            = var.artifact.path
	lambda_image_uri            = var.lambda_image_uri
  }
}

resource "aws_ssm_parameter" "ssm_parameters" {
  for_each = local.ssm_parameters

  name  = "/__deployment__/applications/${var.function_name}/${each.key}"
  type  = "String"
  value = each.value
}
