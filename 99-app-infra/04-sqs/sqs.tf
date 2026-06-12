resource "aws_sqs_queue" "sweep_dlq" {
  for_each = var.enable_sqs ? local.sqs_queues : {}

  name                        = replace(each.value.name, ".fifo", "-dlq.fifo")
  fifo_queue                  = true
  content_based_deduplication = true
  message_retention_seconds   = var.sqs_message_retention_seconds
  sqs_managed_sse_enabled     = true

  tags = merge(var.default_tags, {
    Name        = replace(each.value.name, ".fifo", "-dlq.fifo")
    Environment = var.env
    Service     = "sweep"
    Role        = "dlq"
  })
}

resource "aws_sqs_queue" "sweep" {
  for_each = var.enable_sqs ? local.sqs_queues : {}

  name                        = each.value.name
  fifo_queue                  = true
  content_based_deduplication = true
  visibility_timeout_seconds  = var.sqs_visibility_timeout_seconds
  message_retention_seconds   = var.sqs_message_retention_seconds
  receive_wait_time_seconds   = var.sqs_receive_wait_time_seconds
  sqs_managed_sse_enabled     = true

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.sweep_dlq[each.key].arn
    maxReceiveCount     = var.sqs_max_receive_count
  })

  tags = merge(var.default_tags, {
    Name        = each.value.name
    Environment = var.env
    Service     = "sweep"
    Role        = each.value.role
    Description = each.value.description
  })
}
