locals {
  sqs_name = var.sqs_fullname != null ? var.sqs_fullname : (var.fifo_queue ? "${var.sqs_name}-sqs.fifo" : "${var.sqs_name}-sqs")
  dlq_name = var.dlq_fullname != null ? var.dlq_fullname : (var.fifo_queue ? "${var.sqs_name}-dlq-sqs.fifo" : "${var.sqs_name}-dlq-sqs")
  tags     = merge(var.context.tags, var.additional_tags)
}

resource "aws_sqs_queue" "this" {
  count                             = var.create ? 1 : 0
  name                              = local.sqs_name
  delay_seconds                     = var.delay_seconds
  max_message_size                  = var.max_message_size
  message_retention_seconds         = var.message_retention_seconds
  receive_wait_time_seconds         = var.receive_wait_time_seconds
  visibility_timeout_seconds        = var.visibility_timeout_seconds
  kms_master_key_id                 = var.kms_master_key_id
  sqs_managed_sse_enabled           = var.kms_master_key_id == null ? var.sqs_managed_sse_enabled : false
  kms_data_key_reuse_period_seconds = var.kms_data_key_reuse_period_seconds
  fifo_queue                        = var.fifo_queue
  content_based_deduplication       = var.content_based_deduplication
  deduplication_scope               = var.deduplication_scope
  fifo_throughput_limit             = var.fifo_throughput_limit
  tags                              = merge(local.tags, { Name = local.sqs_name })
}

resource "aws_sqs_queue" "dlq" {
  count                             = var.create && var.create_dlq ? 1 : 0
  name                              = local.dlq_name
  delay_seconds                     = try(coalesce(var.dlq_delay_seconds, var.delay_seconds), null)
  max_message_size                  = var.max_message_size
  message_retention_seconds         = try(coalesce(var.dlq_message_retention_seconds, var.message_retention_seconds), null)
  receive_wait_time_seconds         = try(coalesce(var.dlq_receive_wait_time_seconds, var.receive_wait_time_seconds), null)
  visibility_timeout_seconds        = try(coalesce(var.dlq_visibility_timeout_seconds, var.visibility_timeout_seconds), null)
  fifo_queue                        = var.fifo_queue
  fifo_throughput_limit             = var.fifo_throughput_limit
  content_based_deduplication       = try(coalesce(var.dlq_content_based_deduplication, var.content_based_deduplication), null)
  deduplication_scope               = try(coalesce(var.dlq_deduplication_scope, var.deduplication_scope), null)
  kms_master_key_id                 = var.kms_master_key_id
  sqs_managed_sse_enabled           = var.kms_master_key_id == null ? var.sqs_managed_sse_enabled : false
  kms_data_key_reuse_period_seconds = try(coalesce(var.dlq_kms_data_key_reuse_period_seconds, var.kms_data_key_reuse_period_seconds), null)
  tags                              = merge(local.tags, { Name = local.dlq_name })
}

