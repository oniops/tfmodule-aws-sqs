locals {
  create_queue_policy = var.create && var.create_queue_policy && length(var.sqs_policy) > 0

  sqs_policy = local.create_queue_policy ? {
    Version   = "2012-10-17"
    Statement = var.sqs_policy
  } : null

  create_dlq_policy = var.create_dlq && var.create_dlq_policy && length(var.dlq_policy) > 0

  dlq_policy = local.create_dlq_policy ? {
    Version   = "2012-10-17"
    Statement = var.dlq_policy
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
  count                = var.create && var.create_dlq && var.create_dlq_redrive_allow_policy ? 1 : 0
  queue_url            = aws_sqs_queue.dlq[0].url
  redrive_allow_policy = jsonencode(var.redrive_allow_policy)
}
