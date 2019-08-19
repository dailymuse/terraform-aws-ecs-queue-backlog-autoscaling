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
import os
import sys
import time
from typing import Any, Dict, Mapping, Optional

import boto3

import datadog

# Try importing muselog so we can get additional logging functionality
try:
    import muselog
except ImportError:
    pass

# NOTE: Could make this configurable, but realistically any metric that we would
# want to generate a backlog value (which has scaling as its primary use case) from
# would have a five minute or less resolution.
FIVE_MINUTES: int = 60 * 5

log_level: str = os.environ.get('LOG_LEVEL', 'INFO')

logger: logging.Logger = logging.getLogger('lambda.compute_queue_backlog')
if 'muselog' in sys.modules:
    muselog.setup_logging(
        root_log_level=log_level,
        module_log_levels={
            'lambda.compute_queue_backlog': os.environ.get('MODULE_LOG_LEVEL', 'INFO')
        }
    )
else:
    logger.setLevel(log_level)

dd_api_key: Optional[str] = os.environ.get('DD_API_KEY')
dd_app_key: Optional[str] = os.environ.get('DD_APP_KEY')

if dd_api_key and dd_app_key:
    datadog.initialize(api_key=dd_api_key, app_key=dd_app_key)

ecs = boto3.client('ecs')
cw = boto3.client('cloudwatch')


class InvalidMetricProviderError(Exception):
    """Exception thrown if the specified metric provider is unrecognized."""

    def __init__(self, metric_provider: str) -> None:
        """Create the exception for `metric_provider`."""
        self.metric_provider = metric_provider
        super().__init__(f"'{metric_provider}' is not a valid metric provider.")


def get_queue_metric_from_sqs(event: Mapping[str, Any]) -> int:
    """Retrieve the assigned queue metric for an SQS queue."""
    sqs = boto3.client('sqs')
    queue_url = sqs.get_queue_url(QueueName=event['queue_name'], QueueOwnerAWSAccountId=event['queue_owner_aws_account_id'])['QueueUrl']
    queue_attrs = sqs.get_queue_attributes(QueueUrl=queue_url, AttributeNames=[event['metric_name']])['Attributes']

    return int(queue_attrs.get(event['metric_name'], 0))


def get_queue_metric_from_datadog(event: Mapping[str, Any]) -> int:
    """Determine out the queue backlog value for an SQS queue."""
    now = int(time.time())
    response = datadog.api.Metric.query(
        start=now - FIVE_MINUTES,
        end=now,
        query=f"{event.get('metric_aggregate') or 'max'}:{event['metric_name']}" + "{" + (event.get('metric_filter') or '*') + "}"
    )

    # Should not need to check response status, as DataDog's request API does this
    # Though it's unclear if there are cases where response["status"] != "ok", but
    # response.status_code < 400...

    # We only care about the very last result in the series, since it is most recently
    # known
    last_slice = response['series'][-1]
    samples = last_slice['pointlist']
    _, metric_value = samples[-1]
    return metric_value


def lambda_handler(event: Mapping[str, Any], context: Mapping[str, Any]) -> Dict[str, Any]:
    """Entrypoint to compute the QueueRequiresConsumer and QueueBacklog metrics."""
    metric_provider = event['metric_provider']
    if metric_provider == 'AWS/SQS':
        metric_value = get_queue_metric_from_sqs(event)
    elif metric_provider == 'DATADOG':
        metric_value = get_queue_metric_from_datadog(event)
    else:
        raise InvalidMetricProviderError(metric_provider)

    cluster = event['cluster_name']
    service = event['service_name']
    queue_name = event['queue_name']

    service_desc = ecs.describe_services(cluster=cluster, services=[service])['services'][0]
    num_tasks = service_desc['desiredCount']

    queue_requires_consumer = 1 if num_tasks == 0 and metric_value > 0 else 0
    cw.put_metric_data(
        Namespace='AWS/ECS',
        MetricData=[{
            'MetricName': 'QueueRequiresConsumer',
            'Dimensions': [
                {'Name': 'ClusterName', 'Value': cluster},
                {'Name': 'ServiceName', 'Value': service},
                {'Name': 'QueueName', 'Value': queue_name}
            ],
            'Timestamp': datetime.datetime.utcnow(),
            'Value': queue_requires_consumer
        }]
    )
    logger.debug('Emitted QueueRequiresConsumer=%d for cluster=%s service=%s queue=%s.',
                 queue_requires_consumer,
                 cluster,
                 service,
                 queue_name,
                 extra={'ctx': dict(cluster_name=cluster,
                                    service_name=service,
                                    queue_name=queue_name,
                                    queue_requires_consumer=queue_requires_consumer)})

    msgs_per_sec = int(event.get('est_msgs_per_sec', 1))

    if num_tasks > 0:
        backlog_secs = metric_value / (num_tasks * msgs_per_sec)
    elif metric_value == 0:
        backlog_secs = 0
    else:
        # Backlog is undefined when there are no tasks but a message
        # backlog.
        return {}

    cw.put_metric_data(
        Namespace='AWS/ECS',
        MetricData=[{
            'MetricName': 'QueueBacklog',
            'Dimensions': [
                {'Name': 'ClusterName', 'Value': cluster},
                {'Name': 'ServiceName', 'Value': service},
                {'Name': 'QueueName', 'Value': queue_name}
            ],
            'Timestamp': datetime.datetime.utcnow(),
            'Value': backlog_secs
        }]
    )

    logger.debug('Emitted QueueBacklog=%d for cluster=%s service=%s queue=%s.',
                 backlog_secs,
                 cluster,
                 service,
                 queue_name,
                 extra={'ctx': dict(cluster_name=cluster,
                                    service_name=service,
                                    queue_name=queue_name,
                                    queue_backlog=backlog_secs)})

    return {}
