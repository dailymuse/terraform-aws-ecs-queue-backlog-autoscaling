output "aws_cloudwatch_event_rule_arn" {
  value       = "${aws_cloudwatch_event_rule.compute_queue_backlog.arn}"
  description = "ARN for the CloudWatch Event Rule that invokes the compute queue backlog lambda at a user-defined interval."
}
