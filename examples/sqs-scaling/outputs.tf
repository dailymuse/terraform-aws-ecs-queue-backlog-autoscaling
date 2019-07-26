output "lambda" {
  value       = module.compute_queue_backlog_lambda
  description = "Information about the lambda function."
}

output "aws_cloudwatch_event_rule_arn" {
  value       = module.compute_queue_backlog.aws_cloudwatch_event_rule_arn
  description = "ARN for the CloudWatch Event Rule that invokes the compute queue backlog lambda at a user-defined interval"
}
