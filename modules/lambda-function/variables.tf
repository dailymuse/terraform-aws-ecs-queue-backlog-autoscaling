variable "name" {
  description = "The lambda function name."
  default     = "compute-queue-backlog"
}

variable "grant_access_to_sqs" {
  description = "Set to 'true' (the default) to grant the necessary permissions to read from SQS queues."
  default     = true
}

variable "log_level" {
  description = "Log level to use for Lambda logs. Accepts the standard Python log levels."
  default     = "INFO"
}

variable "tags" {
  description = "Map of AWS tags to add to the Lambda. Note that the 'Name' tag is always added, and is the same as the value of the resource's 'name' attribute by default. The 'Description' tag is added as well."
  default     = {}
}

variable "lambda_layers" {
  description = "Additional lambda layers to add to the lambda."
  default     = []
}

variable "dd_api_key" {
  description = "The API key for the lambda to use when communicating with DataDog. Required to use the lambda with DataDog metrics."
  default     = ""
}

variable "dd_app_key" {
  description = "The Application key for the lambda to use when reading metrics from DataDog. Required to use the lambda with DataDog metrics."
  default     = ""
}

variable "enable_datadog_json_formatter" {
  description = "If Muselog is available to the lambda function, this setting will ensure that its logs are in JSON format for easier parsing by DataDog logs."
  default     = "true"
}

variable "execution_role_arn" {
  description = "IAM role arn to use for lambda execution. If not supplied, this module will create a role with necessary permissions. These permissions are 'cloudwatch:PutMetricData', 'ecs:DescribeServices', 'logs:CreateLogGroup', 'logs:CreateLogStream', and 'logs:PutLogEvents'. If 'grant_access_to_sqs' is 'true', 'sqs:GetQueueUrl' and 'sqs:GetQueueAttributes' are also added."
  default     = ""
}

variable "execution_role_tags" {
  description = "Map of AWS tags to add to the execution role. Note that the 'Name' tag is always added, and is the same as the value of the resource's 'name' attribute by default. The 'Description' tag is added as well."
  default     = {}
}
