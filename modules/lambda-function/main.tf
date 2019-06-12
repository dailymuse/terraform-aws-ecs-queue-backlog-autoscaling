terraform {
  required_version = ">= 0.11.11"
}

data "archive_file" "compute_queue_backlog" {
  type        = "zip"
  source_file = "${path.module}/compute_queue_backlog.py"
  output_path = "${path.module}/compute_queue_backlog.zip"
}

resource "aws_lambda_function" "compute_queue_backlog" {
  filename      = "${data.archive_file.compute_queue_backlog.output_path}"
  function_name = "${var.name}"
  role          = "${var.execution_role_arn != "" ? var.execution_role_arn : element(concat(aws_iam_role.compute_queue_backlog.*.arn, list("")), 0)}"
  handler       = "compute_queue_backlog.lambda_handler"

  source_code_hash = "${base64sha256(file("${data.archive_file.compute_queue_backlog.output_path}"))}"

  runtime = "python3.7"
}

#
#   Lambda Role
#
resource "aws_iam_role" "compute_queue_backlog" {
  count              = "${var.execution_role_arn == "" ? 1 : 0}"
  name               = "${var.name}-role"
  description        = "Grants ${var.name} lambda access to necessary ECS, SQS, and CloudWatch services."
  assume_role_policy = "${data.aws_iam_policy_document.compute_queue_backlog_trust_relationship.json}"
}

#
#   Trust policy
#
data "aws_iam_policy_document" "compute_queue_backlog_trust_relationship" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "compute_queue_backlog" {
  count  = "${var.execution_role_arn == "" ? 1 : 0}"
  name   = "${var.name}-role-policy"
  role   = "${element(concat(aws_iam_role.compute_queue_backlog.*.name, list("")), 0)}"
  policy = "${data.aws_iam_policy_document.compute_queue_backlog.json}"
}

data "aws_iam_policy_document" "compute_queue_backlog" {
  statement {
    effect = "Allow"

    actions = [
      "cloudwatch:PutMetricData",
      "ecs:DescribeServices",
      "sqs:GetQueueUrl",
      "sqs:GetQueueAttributes",
    ]

    resources = ["*"]
  }

  statement {
    effect    = "Allow"
    actions   = ["logs:CreateLogGroup"]
    resources = ["arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"]
  }

  statement {
    effect    = "Allow"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.name}:*"]
  }
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}
