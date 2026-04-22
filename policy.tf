locals {
  create_queue_policy = var.create && var.create_queue_policy && (length(var.sqs_policy) > 0 || var.sqs_access_services != null)
  producer_services = local.create_queue_policy && var.sqs_access_services != null ? {
    for _k, e in coalesce(var.sqs_access_services.producer, {}) : e.service => e.arn...
  } : {}

  consumer_services = local.create_queue_policy && var.sqs_access_services != null ? {
    for _k, e in coalesce(var.sqs_access_services.consumer, {}) : e.service => e.arn...
  } : {}

  sqs_policy = local.create_queue_policy ? {
    Version = "2012-10-17",
    Statement = concat(
      var.sqs_policy,
      length(local.producer_services) > 0 ? [{
        Sid       = "AllowProduceForServices"
        Effect    = "Allow"
        Principal = { Service = tolist(keys(local.producer_services)) }
        Action    = tolist(["sqs:SendMessage"])
        Resource  = aws_sqs_queue.this[0].arn
        Condition = { StringEquals = { "aws:SourceArn" = tolist(flatten(values(local.producer_services))) } }
      }] : [],
      length(local.consumer_services) > 0 ? [{
        Sid       = "AllowConsumeForServices"
        Effect    = "Allow"
        Principal = { Service = tolist(keys(local.consumer_services)) }
        Action = tolist([
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:ChangeMessageVisibility"
        ])
        Resource  = aws_sqs_queue.this[0].arn
        Condition = { StringEquals = { "aws:SourceArn" = tolist(flatten(values(local.consumer_services))) } }
      }] : []
    )
  } : null

  create_dlq_policy = var.create_dlq && var.create_dlq_policy && (length(var.dlq_policy) > 0 || var.dlq_access_services != null)
  dlq_producer_services = local.create_dlq_policy && var.dlq_access_services != null ? {
    for _k, e in coalesce(var.dlq_access_services.producer, {}) : e.service => e.arn...
  } : {}

  dlq_consumer_services = local.create_dlq_policy && var.dlq_access_services != null ? {
    for _k, e in coalesce(var.dlq_access_services.consumer, {}) : e.service => e.arn...
  } : {}

  dlq_policy = local.create_dlq_policy ? {
    Version = "2012-10-17",
    Statement = concat(
      var.dlq_policy,
      length(local.dlq_producer_services) > 0 ? [{
        Sid       = "AllowProduceForServices"
        Effect    = "Allow"
        Principal = { Service = tolist(keys(local.dlq_producer_services)) }
        Action    = tolist(["sqs:SendMessage"])
        Resource  = aws_sqs_queue.dlq[0].arn
        Condition = { StringEquals = { "aws:SourceArn" = tolist(flatten(values(local.dlq_producer_services))) } }
      }] : [],
      length(local.dlq_consumer_services) > 0 ? [{
        Sid       = "AllowConsumeForServices"
        Effect    = "Allow"
        Principal = { Service = tolist(keys(local.dlq_consumer_services)) }
        Action = tolist([
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:ChangeMessageVisibility"
        ])
        Resource  = aws_sqs_queue.dlq[0].arn
        Condition = { StringEquals = { "aws:SourceArn" = tolist(flatten(values(local.dlq_consumer_services))) } }
      }] : []
    )
  } : null
}

resource "aws_sqs_queue_policy" "this" {
  count     = local.create_queue_policy ? 1 : 0
  queue_url = aws_sqs_queue.this[0].url
  policy    = jsonencode(local.sqs_policy)
}

resource "aws_sqs_queue_policy" "dlq" {
  count     = local.create_dlq_policy ? 1 : 0
  queue_url = aws_sqs_queue.dlq[0].url
  policy    = jsonencode(local.dlq_policy)
}

resource "aws_sqs_queue_redrive_policy" "dlq" {
  count     = var.create && var.create_dlq ? 1 : 0
  queue_url = aws_sqs_queue.this[0].url
  redrive_policy = jsonencode(merge(
    { maxReceiveCount = var.redrive_max_receive_count },
    { deadLetterTargetArn = aws_sqs_queue.dlq[0].arn }
  ))
}

resource "aws_sqs_queue_redrive_allow_policy" "dlq" {
  count     = var.create && var.create_dlq && var.create_dlq_redrive_allow_policy ? 1 : 0
  queue_url = aws_sqs_queue.dlq[0].url
  redrive_allow_policy = jsonencode(merge(
    { redrivePermission = "byQueue", sourceQueueArns = [aws_sqs_queue.this[0].arn] },
    coalesce(var.dlq_redrive_allow_policy, {})
  ))
}

output "dlq_policy" {
  value = jsonencode(local.dlq_policy)
}
