terraform {
  required_version = ">= 0.12"
}

locals {
  appautoscaling_target_info = {
    resource_id        = "service/${var.cluster_name}/${var.service_name}"
    scalable_dimension = "ecs:service:DesiredCount"
    service_namespace  = "ecs"
  }
}

resource "aws_appautoscaling_target" "service_appautoscaling_target" {
  count = var.create_appautoscaling_target ? 1 : 0

  max_capacity       = var.max_capacity
  min_capacity       = var.min_capacity
  resource_id        = local.appautoscaling_target_info.resource_id
  scalable_dimension = local.appautoscaling_target_info.scalable_dimension
  service_namespace  = local.appautoscaling_target_info.service_namespace
}

locals {
  service_appautoscaling_target = var.create_appautoscaling_target ? aws_appautoscaling_target.service_appautoscaling_target[0] : local.appautoscaling_target_info
}

resource "aws_appautoscaling_policy" "queue_backlog_scaling_policy" {
  name               = "${var.service_name}-${var.queue_name}-queue-backlog-scaling-policy"
  policy_type        = "TargetTrackingScaling"
  resource_id        = local.service_appautoscaling_target.resource_id
  scalable_dimension = local.service_appautoscaling_target.scalable_dimension
  service_namespace  = local.service_appautoscaling_target.service_namespace

  target_tracking_scaling_policy_configuration {
    target_value       = var.target_value
    scale_in_cooldown  = var.scalein_cooldown
    scale_out_cooldown = var.scaleout_cooldown

    customized_metric_specification {
      metric_name = "QueueBacklog"
      namespace   = "AWS/ECS"
      statistic   = var.target_value_statistic

      dimensions {
        name  = "ClusterName"
        value = var.cluster_name
      }

      dimensions {
        name  = "ServiceName"
        value = var.service_name
      }

      dimensions {
        name  = "QueueName"
        value = var.queue_name
      }
    }
  }
}

resource "aws_appautoscaling_policy" "queue_requires_consumer_scaling_policy" {
  name               = "${var.service_name}-${var.queue_name}-queue-requires-consumer-scaling-policy"
  policy_type        = "StepScaling"
  resource_id        = local.service_appautoscaling_target.resource_id
  scalable_dimension = local.service_appautoscaling_target.scalable_dimension
  service_namespace  = local.service_appautoscaling_target.service_namespace

  step_scaling_policy_configuration {
    adjustment_type         = "ExactCapacity"
    cooldown                = var.scaleout_cooldown
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = var.rampup_capacity
    }
  }
}

resource "aws_cloudwatch_metric_alarm" "queue_requires_consumer_alarm" {
  alarm_name          = "ecs-${var.service_name}-${var.queue_name}-queue-requires-consumer"
  alarm_description   = "Managed by Terraform"
  alarm_actions       = [aws_appautoscaling_policy.queue_requires_consumer_scaling_policy.arn]
  comparison_operator = var.queue_requires_consumer_alarm_comparison_op
  evaluation_periods  = var.queue_requires_consumer_alarm_evaluation_periods
  metric_name         = "QueueRequiresConsumer"
  namespace           = "AWS/ECS"
  period              = var.queue_requires_consumer_alarm_period
  statistic           = var.queue_requires_consumer_alarm_statistic
  threshold           = "0"

  dimensions = {
    ClusterName = var.cluster_name
    ServiceName = var.service_name
    QueueName   = var.queue_name
  }
}
