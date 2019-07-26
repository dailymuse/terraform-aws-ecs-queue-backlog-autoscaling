output "arn" {
  value       = "${module.compute_queue_backlog.arn}"
  description = "This is compute queue backlog lambda's unqualified arn."
}

output "name" {
  value       = "${module.compute_queue_backlog.name}"
  description = "This is compute queue backlog lambda's function name."
}

output "execution_role_arn" {
  value       = "${module.compute_queue_backlog.execution_role_arn}"
  description = "This is the ARN for the execution role that was created for the lambda. It will be empty if you supplied your own."
}
