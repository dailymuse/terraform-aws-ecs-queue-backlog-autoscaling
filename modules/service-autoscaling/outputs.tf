output "queue_requires_consumer_scaling_policy_arn" {
  value       = "${aws_appautoscaling_policy.queue_requires_consumer_scaling_policy.arn}"
  description = "ARN for the StepScaling policy tied to QueueRequiresConsumer metric."
}

output "queue_backlog_scaling_policy_arn" {
  value       = "${aws_appautoscaling_policy.queue_backlog_scaling_policy.arn}"
  description = "ARN for the TargetTrackingScaling policy tied to QueueBacklog metric."
}
