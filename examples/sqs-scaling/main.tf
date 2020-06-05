terraform {
  required_version = ">= 0.12"
}

resource "aws_sqs_queue" "main" {
  count = var.create_queue ? 1 : 0

  name = var.queue_name
}

data "aws_sqs_queue" "main" {
  count = var.create_queue ? 0 : 1

  name = var.queue_name
}

resource "aws_ecs_task_definition" "main" {
  count = var.create_service ? 1 : 0

  family                   = var.service_name
  requires_compatibilities = ["EC2"]
  cpu                      = 1024
  memory                   = 128

  container_definitions = jsonencode([
    {
      name      = "test"
      image     = "busybox"
      essential = true
      command   = ["echo", "yes"]
    }
  ])
}

resource "aws_ecs_service" "main" {
  count = var.create_service ? 1 : 0

  name            = var.service_name
  task_definition = aws_ecs_task_definition.main[count.index].arn
  cluster         = var.cluster_id

  lifecycle {
    ignore_changes = [desired_count]
  }
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

  depends_on_service = var.create_service ? aws_ecs_service.main[0] : null
}

resource "aws_sqs_queue_policy" "main" {
  queue_url = var.create_queue ? aws_sqs_queue.main[0].id : data.aws_sqs_queue.main[0].url
  policy    = data.aws_iam_policy_document.sqs.json
}

data "aws_iam_policy_document" "sqs" {
  statement {
    effect    = "Allow"
    actions   = ["sqs:GetQueueUrl", "sqs:GetQueueAttributes"]
    resources = [var.create_queue ? aws_sqs_queue.main[0].arn : data.aws_sqs_queue.main[0].arn]

    principals {
      identifiers = [module.compute_queue_backlog_lambda.execution_role_arn]

      type = "AWS"
    }
  }
}
