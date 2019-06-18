variable "cluster_name" {
  description = "ECS cluster name. Uses default cluster if not supplied."
  default     = ""
}

variable "service_name" {
  description = "ECS service name"
}

variable "service_max_capacity" {
  description = "Maximum number of tasks that the autoscaling policy can set for the service."
  default     = 1
}

variable "service_min_capacity" {
  description = "Minimum number of tasks that the autoscaling policy can set for the service."
  default     = 0
}

variable "service_est_msgs_per_sec" {
  description = "Non-negative integer that represents the estimated number of messages the service can consume from its queue in one second."
}

variable "queue_name" {
  description = "Name of the queue to compute QueueBacklog metric for."
}

variable "queue_owner_aws_account_id" {
  description = "AWS account id that provides the queue. If not provided, will use the caller's account id."
  default     = ""
}

variable "queue_backlog_target_value" {
  description = "Queue backlog (in seconds) to maintain for the service when under maximum load."
}

variable "lambda_name" {
  description = "The lambda function name."
  default     = "compute-queue-backlog"
}

variable "lambda_invocation_interval" {
  description = "Rate or cron expression to determine the interval for QueueBacklog metric refresh."
  default     = "rate(1 minute)"
}
