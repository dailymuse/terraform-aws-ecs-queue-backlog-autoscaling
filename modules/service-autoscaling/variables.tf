variable "cluster_name" {
  description = "ECS cluster name. Uses default cluster if not supplied."
  default     = ""
}

variable "service_name" {
  description = "ECS service name"
}

variable "max_capacity" {
  description = "Maximum number of tasks that the autoscaling policy can set for the service."
}

variable "min_capacity" {
  description = "Minimum number of tasks that the autoscaling policy can set for the service."
  default     = 0
}

variable "queue_name" {
  description = "Name of the queue to compute QueueBacklog metric for."
}

variable "target_value" {
  description = "Queue backlog (in seconds) to maintain for the service when under maximum load."
}

variable "target_value_statistic" {
  description = "Metric statistic to use when aggregating QueueBacklog over a period."
  default     = "Average"
}

variable "scalein_cooldown" {
  description = "Number of seconds to wait after a scaling operation before a scale-in operation can take place."
  default     = 60
}

variable "scaleout_cooldown" {
  description = "Number of seconds to wait after a scaling operation before a scale-out operation can take place."
  default     = 60
}

variable "rampup_capacity" {
  description = "Number of tasks to start as the immediate response to a QueueRequiresConsumer non-zero value."
  default     = 1
}

variable "queue_requires_consumer_alarm_period" {
  description = "Number of seconds to aggregate QueueRequiresConsumer metric before testing against the alarm threshold."
  default     = 60
}

variable "queue_requires_consumer_alarm_statistic" {
  description = "Metric statistic to use when aggregating QueueBacklog over a period."
  default     = "Average"
}

variable "queue_requires_consumer_alarm_evaluation_periods" {
  description = "Number of periods to aggregate QueueRequiresConsumer metric over when comparing against the alarm threshold."
  default     = 1
}

variable "queue_requires_consumer_alarm_comparison_op" {
  description = "Operator to use when comparing QueueRequiresConsumer against the alarm threshold."
  default     = "GreaterThanThreshold"
}
