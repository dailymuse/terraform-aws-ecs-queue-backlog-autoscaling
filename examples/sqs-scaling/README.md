# Example of scaling an ECS service based on an SQS queue

This folder shows an example of Terraform code that uses the lambda-function module
and top-level terraform-aws-ecs-queue-backlog-autoscaling module to deploy a
Compute Queue Backlog lambda in AWS and then create autoscaling policies,
CloudWatch Alarms, and CloudWatch Rules that use the lambda output to trigger
scaling actions on a service of your choice based on the queue backlog for an
SQS queue of your choice.

## Requirements
* Existing AWS account with an ECS cluster and service
* Existing SQS queue on the same AWS account as the ECS cluster
