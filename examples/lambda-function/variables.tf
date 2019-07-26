variable "dd_api_key" {
  description = "The API key for the lambda to use when communicating with DataDog. Required to use the lambda with DataDog metrics."
  default     = ""
}

variable "dd_app_key" {
  description = "The Application key for the lambda to use when reading metrics from DataDog. Required to use the lambda with DataDog metrics."
  default     = ""
}
