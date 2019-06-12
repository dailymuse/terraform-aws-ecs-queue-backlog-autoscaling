# Compute Queue Backlog Lambda Function

This folder contains a [Terraform](https://www.terraform.io/) module to deploy an
[AWS Lambda](https://aws.amazon.com/lambda/) function that computes two [AWS CloudWatch](https://aws.amazon.com/cloudwatch/)
metrics, `QueueBacklog` and `QueueRequiresConsumer`, for queues-driven ECS services (currently supports SQS).


## How do you use this module?

This folder defines a [Terraform module](https://www.terraform.io/docs/modules/usage.html),
which you can use in your code by adding a `module` configuration and setting its `source` parameter to URL of this folder:

```hcl
module "compute_queue_backlog" {
  source = "github.com/dailymuse/terraform-aws-ecs-queue-backlog-autoscaling//modules/lambda-function"

  # ... See variables.tf for the parameters you must define for this module
}
```

## What's included in this module?

This module creates the following resources.

* [Lambda Function](#lambda-function)
* [Roles and Permissions](#roles-and-permissions)


### Lambda Function
The lambda function computes QueueBacklog and QueueRequiresConsumer CloudWatch
metrics via [compute_queue_backlog.py](compute_queue_backlog.py). The function
must take the following parameters as its input.

* cluster_name - The name of the ECS cluster
* service_name - The name of the ECS service that consumes from the target queue
* queue_owner_aws_account_id - The AWS account id that provides the target queue
* queue_name - The target queue name

Optional parameters are as follows.
* est_msgs_per_sec - Non-negative integer that represents the estimated number of messages the service can consume from the target queue in one second. Default: 1.

The lambda arn is exported as `lambda_arn`.


### Roles and Permissions
This module will create an execution role for the lambda function, a trust policy,
and an inline policy for the execution role. The trust policy allows AWS Lambda to
assume the execution role. The inline policy grants the execution role holder access
to the ECS, SQS, and CloudWatch actions it needs to compute its metrics.  

The execution role ARN is exported as an output variable if you need to add additional permissions.

You can disable the creation of the execution role and its policies if needed by providing the execution role arn via the
`execution_role_arn` variable.


## What's NOT included in this module?

This module does NOT handle the following items, which you may want to provide on your own.

* [Lambda invocation](#lambda-invocation)
* [Service Autoscaling](#service-autoscaling)


### Lambda Invocation

This module does not include any resources to invoke the lambda function.
However, the parent module will create CloudWatch event and event rules to trigger
the lambda at a regular interval. The parent module has limited flexibility in
this regard.


### Service Autoscaling

This module does not include any resources to autoscale service(s) as a function of
the `QueueBacklog` or `QueueRequiresConsumer` metric values. The default implementation
for autoscaling is in the [service-autoscaling](../service-autoscaling) module.
