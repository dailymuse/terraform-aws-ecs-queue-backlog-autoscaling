terraform {
  required_version = ">= 0.12"
}

module "compute_queue_backlog" {
  source = "../../modules/lambda-function"

  name = "compute-queue-backlog-example"

  log_level = "DEBUG"

  dd_api_key = var.dd_api_key
  dd_app_key = var.dd_app_key
}
