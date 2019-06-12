variable "name" {
  description = "The lambda function name."
}

variable "execution_role_arn" {
  description = "IAM role arn to use for lambda execution. If not supplied, this module will create a role with necessary permissions."
  default     = ""
}
