# AWS ECS Service Autoscaling by QueueBacklog

This repo contains a [Terraform](https://www.terraform.io/) module to autoscale
an AWS ECS service based on the `QueueBacklog` and `QueueRequiresConsumer` [AWS CloudWatch](https://aws.amazon.com/cloudwatch/)
metrics. Additionally, this repo contains a nested module to deploy an
[AWS Lambda](https://aws.amazon.com/lambda/) function that computes the two metrics.


## How to use this Module

This repo has the following folder structure:

* [modules](modules): This folder contains modules to create resources that use and compute `QueueBacklog` and `QueueRequiresConsumer`.
* root: The root directory exposes a simplified interface to the modules in order to implement service autoscaling.
