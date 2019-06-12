# ECS Service Autoscaling based on queue backlog

This folder contains a [Terraform](https://www.terraform.io/) module to deploy an
app autoscaling policies for an AWS ECS service based on the `QueueBacklog` and `QueueRequiresConsumer`
[AWS CloudWatch](https://aws.amazon.com/cloudwatch/) metrics.


## How do you use this module?

This folder defines a [Terraform module](https://www.terraform.io/docs/modules/usage.html),
which you can use in your code by adding a `module` configuration and setting its `source` parameter to URL of this folder:

```hcl
module "compute_queue_backlog" {
  source = "github.com/dailymuse/terraform-aws-ecs-queue-backlog-autoscaling//modules/service-autoscaling"

  # ... See variables.tf for the parameters you must define for this module
}
```

## What's included in this module?

This module creates the following resources.

* [App Autoscaling Target and Policies](#app-autoscaling-target-and-policies)
* [CloudWatch Alarm](#cloudwatch-alarm)


### App Autoscaling Target and Policies
This module will create an App Autoscaling Target (essentially an autoscaling group)
for the target service, a target tracking scaling policy that maintains the service
desired count at a value sufficient to keep `QueueBacklog` at the `queue_backlog_target_value`,
and a step scaling policy that ensures at least one service task is running up when
`QueueBacklog` is greater than zero, but below `queue_backlog_target_value`.


### CloudWatch Alarm
This module will create a CloudWatch alarm for the `QueueRequiresConsumer` metric.


## What's NOT included in this module?

This module does NOT handle the following items, which you may want to provide on your own.

* [Metric Creation](#metric-creation)

### Metric Creation

This module does not include the resources to compute `QueueBacklog` and `QueueRequiresConsumer`.
You can find a default implementation using AWS Lambda in [lambda-function](../lambda-function).
