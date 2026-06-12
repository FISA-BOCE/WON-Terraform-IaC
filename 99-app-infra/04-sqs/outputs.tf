output "sqs_sweep_queue_urls" {
  description = "SQS queue URLs for the sweep workflow"
  value = {
    for key, queue in aws_sqs_queue.sweep :
    key => queue.url
  }
}

output "sqs_sweep_queue_arns" {
  description = "SQS queue ARNs for the sweep workflow"
  value = {
    for key, queue in aws_sqs_queue.sweep :
    key => queue.arn
  }
}

output "sqs_sweep_dlq_urls" {
  description = "SQS DLQ URLs for the sweep workflow"
  value = {
    for key, queue in aws_sqs_queue.sweep_dlq :
    key => queue.url
  }
}

output "card_channel_sqs_policy_arn" {
  description = "IAM policy ARN for Card Channel SQS access"
  value       = try(aws_iam_policy.card_channel_sqs_access[0].arn, null)
}

output "invest_channel_sqs_policy_arn" {
  description = "IAM policy ARN for Invest Channel SQS access"
  value       = try(aws_iam_policy.invest_channel_sqs_access[0].arn, null)
}
