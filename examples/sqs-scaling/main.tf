terraform {
  required_version = ">= 0.12"
}

data "aws_sqs_queue" "this" {
  name = var.queue_name
}

module "compute_queue_backlog_lambda" {
  source = "../../modules/lambda-function"

  name = "compute-queue-backlog-full-example"

  log_level = "DEBUG"
}

module "compute_queue_backlog" {
  source = "../.."

  cluster_name = var.cluster_id

  service_name             = var.service_name
  service_max_capacity     = var.service_max_capacity
  service_min_capacity     = var.service_min_capacity
  service_est_msgs_per_sec = var.service_est_msgs_per_sec

  queue_name                 = var.queue_name
  queue_backlog_target_value = var.queue_backlog_target_value

  lambda_name = module.compute_queue_backlog_lambda.name
}

resource "aws_sqs_queue_policy" "this" {
  queue_url = data.aws_sqs_queue.this.url
  policy    = data.aws_iam_policy_document.sqs.json
}

data "aws_iam_policy_document" "sqs" {
  statement {
    effect    = "Allow"
    actions   = ["sqs:GetQueueUrl", "sqs:GetQueueAttributes"]
    resources = [data.aws_sqs_queue.this.arn]

    principals {
      identifiers = [module.compute_queue_backlog_lambda.execution_role_arn]

      type = "AWS"
    }
  }
}
