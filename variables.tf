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

variable "metric_provider" {
  description = "Service that provides metric data required to compute the queue backlog value. Valid values are 'AWS/SQS' and 'DATADOG'."
  default     = "AWS/SQS"
}

variable "metric_name" {
  description = "The name of the metric the lambda uses to derive the queue backlog value."
  default     = "ApproximateNumberOfMessages"
}

variable "queue_name" {
  description = "Name of the queue to compute QueueBacklog metric for. For the 'AWS/SQS' metric provider, the name must be the name of the SQS queue. It can be any value you wish for other metric providers."
}

variable "queue_backlog_target_value" {
  description = "Queue backlog (in seconds) to maintain for the service when under maximum load. Defaults to 600 seconds (10 minutes)."
  default     = 600
}

variable "lambda_name" {
  description = "The lambda function name."
  default     = "compute-queue-backlog"
}

variable "lambda_invocation_interval" {
  description = "Rate or cron expression to determine the interval for QueueBacklog metric refresh."
  default     = "rate(1 minute)"
}


# AWS/SQS-specific configuration

variable "queue_owner_aws_account_id" {
  description = "AWS account id that provides the queue. If not provided, will use the caller's account id. Only valid for 'AWS/SQS' metric provider."
  default     = ""
}


# DataDog-specific configuration

variable "metric_filter" {
  description = "The filter condition to apply to the metric query. For DataDog, this is equivalent to the 'over' section in Metrics Explorer."
  default     = ""
}

variable "metric_aggregate" {
  description = "The aggregate function to use for metric rollup. Valid values are 'min', 'max', 'avg', and 'sum'."
  default     = ""
}

variable "dd_api_key" {
  description = "The API key for the lambda to use when communicating with DataDog. Required if the metric_provider is 'DATADOG'."
  default     = ""
}

variable "dd_app_key" {
  description = "The Application key for the lambda to use when reading metrics from DataDog. Required if the metric_provider is 'DATADOG'."
  default     = ""
}
