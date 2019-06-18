variable "name" {
  description = "The lambda function name."
  default     = "compute-queue-backlog"
}

variable "execution_role_arn" {
  description = "IAM role arn to use for lambda execution. If not supplied, this module will create a role with necessary permissions. These permissions are 'cloudwatch:PutMetricData', 'ecs:DescribeServices', 'sqs:GetQueueUrl', 'sqs:GetQueueAttributes', 'logs:CreateLogGroup', 'logs:CreateLogStream', and 'logs:PutLogEvents'."
  default     = ""
}
