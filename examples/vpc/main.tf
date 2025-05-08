data "vy_artifact_version" "this" {
  application = "user-service"
}

module "account_metadata" {
  source = "github.com/nsbno/terraform-aws-account-metadata?ref=0.3.1"
}

module "lambda" {
  source = "../../"

  name = "get-users"

  artifact_type = "s3"
  artifact      = data.vy_artifact_version.this

  runtime = "python3.11"
  handler = "handler.main"

  subnet_ids         = module.account_metadata.network.private_subnet_ids
  security_group_ids = [aws_security_group.lambda_security_group.id]
}

resource "aws_security_group" "lambda_security_group" {
  name        = "user-service-sg"
  description = "Security group for Lambda function user-service"
  vpc_id      = module.account_metadata.network.vpc_id

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
