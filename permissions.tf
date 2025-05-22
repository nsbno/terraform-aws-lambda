data "aws_iam_policy_document" "allow_ecr_image_access" {
  statement {
	effect = "Allow"

	actions = [
	  "ecr:BatchGetImage",
	  "ecr:GetDownloadUrlForLayer"
	]
	resources = ["*"]
  }
}

resource "aws_iam_role_policy" "allow_ecr" {
  role   = aws_iam_role.this.id
  policy = data.aws_iam_policy_document.allow_ecr_image_access.json
}
