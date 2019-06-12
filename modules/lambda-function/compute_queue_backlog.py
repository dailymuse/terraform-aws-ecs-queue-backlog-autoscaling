"""Determine queue backlog for an ECS service or task group.

This lambda function computes the following metrics.
    QueueBacklog - Non-negative integer that represents the estimated duration
        in seconds that a service or task group will take to process all items on a
        queue at the time of computation.
    QueueRequiresConsumer - Binary value (0 or 1), to be interpreted by the reader as a boolean,
        that indicates if a queue is backlogged with no consumer. If so, the value
        is '1'. Otherwise, the value is '0'.
"""

import datetime
import logging

import boto3


logger = logging.getLogger('lambda.compute_queue_backlog')
logger.setLevel('INFO')

sqs = boto3.client('sqs')
ecs = boto3.client('ecs')
cw = boto3.client('cloudwatch')


def lambda_handler(event, context):
    """Entrypoint to compute the QueueRequiresConsumer and QueueBacklog metrics."""
    cluster = event["cluster_name"]
    service = event["service_name"]
    account_id = event["queue_owner_aws_account_id"]
    queue_name = event["queue_name"]
    msgs_per_sec = int(event.get("est_msgs_per_sec", 1))
    service_desc = ecs.describe_services(cluster=cluster, services=[service])["services"][0]
    num_tasks = service_desc["desiredCount"]
    queue_url = sqs.get_queue_url(QueueName=queue_name, QueueOwnerAWSAccountId=account_id)['QueueUrl']
    queue_attrs = sqs.get_queue_attributes(QueueUrl=queue_url, AttributeNames=['ApproximateNumberOfMessages'])['Attributes']
    approx_num_msgs = int(queue_attrs.get('ApproximateNumberOfMessages', 0))
    queue_requires_consumer = 1 if num_tasks == 0 and approx_num_msgs > 0 else 0
    cw.put_metric_data(
        Namespace='AWS/ECS',
        MetricData=[{
            'MetricName': 'QueueRequiresConsumer',
            'Dimensions': [{'Name': 'ClusterName', 'Value': cluster}, {'Name': 'ServiceName', 'Value': service}, {'Name': 'QueueName', 'Value': queue_name}],
            'Timestamp': datetime.datetime.utcnow(),
            'Value': queue_requires_consumer
        }]
    )

    logger.info('Emitted QueueRequiresConsumer=%d for cluster=%s service=%s queue=%s.', queue_requires_consumer, cluster, service, queue_name)

    if num_tasks > 0:
        backlog_secs = approx_num_msgs / (num_tasks * msgs_per_sec)
    elif approx_num_msgs == 0:
        backlog_secs = 0
    else:
        # Backlog is undefined when there are no tasks but a message
        # backlog.
        return {}

    cw.put_metric_data(
        Namespace='AWS/ECS',
        MetricData=[{
            'MetricName': 'QueueBacklog',
            'Dimensions': [{'Name': 'ClusterName', 'Value': cluster}, {'Name': 'ServiceName', 'Value': service}, {'Name': 'QueueName', 'Value': queue_name}],
            'Timestamp': datetime.datetime.utcnow(),
            'Value': backlog_secs
        }]
    )

    logger.info('Emitted QueueBacklog=%d for cluster=%s service=%s queue=%s.', backlog_secs, cluster, service, queue_name)

    return {}
