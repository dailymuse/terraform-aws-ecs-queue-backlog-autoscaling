output "arn" {
  value       = "${aws_lambda_function.compute_queue_backlog.arn}"
  description = "This is compute queue backlog lambda's unqualified arn."
}

output "name" {
  value       = "${aws_lambda_function.compute_queue_backlog.function_name}"
  description = "This is compute queue backlog lambda's function name."
}

output "execution_role_arn" {
  value       = "${element(concat(aws_iam_role.compute_queue_backlog.*.arn, list("")), 0)}"
  description = "This is the ARN for the execution role that was created for the lambda. It will be empty if you supplied your own."
}
