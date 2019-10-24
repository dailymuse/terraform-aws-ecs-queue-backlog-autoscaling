terraform {
  required_version = ">= 0.12"
}

locals {
  datadog = {
    account_id    = 464622532012
    layer_runtime = "Python37"
    layer_version = 4
  }
}

data "archive_file" "compute_queue_backlog" {
  type        = "zip"
  source_file = "${path.module}/compute_queue_backlog.py"
  output_path = "${path.module}/compute_queue_backlog.zip"
}

resource "aws_lambda_function" "compute_queue_backlog" {
  filename      = data.archive_file.compute_queue_backlog.output_path
  function_name = var.name
  role          = var.execution_role_arn != "" ? var.execution_role_arn : element(concat(aws_iam_role.compute_queue_backlog.*.arn, list("")), 0)
  handler       = "compute_queue_backlog.lambda_handler"

  source_code_hash = filebase64sha256(data.archive_file.compute_queue_backlog.output_path)

  layers = concat(
    ["arn:aws:lambda:${data.aws_region.current.name}:${local.datadog.account_id}:layer:Datadog-${local.datadog.layer_runtime}:${local.datadog.layer_version}"],
    var.lambda_layers
  )


  environment {
    variables = {
      LOG_LEVEL                     = var.log_level
      DD_API_KEY                    = var.dd_api_key
      DD_APP_KEY                    = var.dd_app_key
      ENABLE_DATADOG_JSON_FORMATTER = var.enable_datadog_json_formatter
    }
  }

  runtime = "python3.7"

  tags = merge(
    {
      Name        = var.name
      Description = "Computes the QueueBacklog and QueueRequiresConsumer metrics."
    },
    var.tags
  )
}

#
#   Lambda Role
#
resource "aws_iam_role" "compute_queue_backlog" {
  count              = var.execution_role_arn == "" ? 1 : 0
  name               = "${var.name}-role"
  description        = "Grants ${var.name} lambda access to necessary AWS services."
  assume_role_policy = data.aws_iam_policy_document.compute_queue_backlog_trust_relationship.json

  tags = merge(
    {
      Name        = "${var.name}-role"
      Description = "Grants ${var.name} lambda access to necessary AWS services."
    },
    var.execution_role_tags
  )
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
  count  = var.execution_role_arn == "" ? 1 : 0
  name   = "${var.name}-role-policy"
  role   = "${element(concat(aws_iam_role.compute_queue_backlog.*.name, list("")), 0)}"
  policy = "${data.aws_iam_policy_document.compute_queue_backlog.json}"
}

resource "aws_iam_role_policy" "compute_queue_backlog_sqs" {
  count  = var.execution_role_arn == "" && var.grant_access_to_sqs ? 1 : 0
  name   = "${var.name}-role-policy-sqs"
  role   = element(concat(aws_iam_role.compute_queue_backlog.*.name, list("")), 0)
  policy = data.aws_iam_policy_document.compute_queue_backlog_sqs.json
}

data "aws_iam_policy_document" "compute_queue_backlog" {
  statement {
    effect = "Allow"

    actions = [
      "cloudwatch:PutMetricData",
      "ecs:DescribeServices",
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

data "aws_iam_policy_document" "compute_queue_backlog_sqs" {
  statement {
    effect = "Allow"

    actions = [
      "sqs:GetQueueUrl",
      "sqs:GetQueueAttributes",
    ]

    resources = ["*"]
  }
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}
