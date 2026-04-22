variable "context" {
  description = "Specify context values. This module uses the tfmodule-context Terraform module to define SQS services and resources, providing a standardized naming policy and tagging conventions, and a consistent datasource reference module. For more information about Context, see the https://github.com/oniops/tfmodule-context Terraform module."
  type        = any
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = <<EOF
Specify tags for resources created in this module.

Example)
  tags = {
    "ExpirationDate"  = "20260102"
    "PurposeOfUse"    = "PoC"
  }
EOF
}

variable "create" {
  description = "Determines whether SQS queue resources will be created"
  type        = bool
  default     = true
}

################################################################################
# Queue
################################################################################

variable "sqs_name" {
  description = "This is the human-readable name of the queue. If omitted, the name will be derived from the context naming convention. For FIFO queues, the `.fifo` suffix is appended automatically. Ignored when `sqs_fullname` is set"
  type        = string
  default     = null
}

variable "sqs_fullname" {
  description = "The fully qualified name of the queue. When set, the value is used as-is and overrides the name derived from `sqs_name` and the context naming convention. Useful when the queue name must follow a custom format outside the module's naming policy. For FIFO queues, the `.fifo` suffix must be included manually"
  type        = string
  default     = null
}

variable "delay_seconds" {
  description = "The time in seconds that the delivery of all messages in the queue will be delayed. An integer from 0 to 900 (15 minutes). Default is 0 (no delay)"
  type        = number
  default     = 0
}

variable "max_message_size" {
  description = "The limit of how many bytes a message can contain before Amazon SQS rejects it. An integer from 1024 bytes (1 KiB) up to 262144 bytes (256 KiB). Default is 262144 (256 KiB)"
  type        = number
  default     = 262144
}

variable "message_retention_seconds" {
  description = "The number of seconds Amazon SQS retains a message. Integer representing seconds, from 60 (1 minute) to 1209600 (14 days). Default is 345600 (4 days)"
  type        = number
  default     = 345600
}

variable "receive_wait_time_seconds" {
  description = "The time for which a ReceiveMessage call will wait for a message to arrive (long polling) before returning. An integer from 0 to 20 (seconds). Setting to a positive value enables long polling. Default is 0 (short polling)"
  type        = number
  default     = 0
}

variable "visibility_timeout_seconds" {
  description = "The visibility timeout for the queue, in seconds. During this time, the message is invisible to other consumers after being received. An integer from 0 to 43200 (12 hours). Default is 30"
  type        = number
  default     = 30
}

################################################################################
# Encryption
################################################################################

variable "sqs_managed_sse_enabled" {
  description = "Boolean to enable server-side encryption (SSE) of message content with SQS-owned encryption keys. Mutually exclusive with `kms_master_key_id`. When set to `true`, `kms_master_key_id` must not be set"
  type        = bool
  default     = true
}

variable "kms_master_key_id" {
  description = "The ID of an AWS-managed customer master key (CMK) for Amazon SQS or a custom CMK. Setting this value enables KMS encryption and `sqs_managed_sse_enabled` must be set to `false`"
  type        = string
  default     = null
}

variable "kms_data_key_reuse_period_seconds" {
  description = "The length of time, in seconds, for which Amazon SQS can reuse a data key to encrypt or decrypt messages before calling AWS KMS again. An integer representing seconds, between 60 seconds (1 minute) and 86,400 seconds (24 hours). Default is 300 (5 minutes)"
  type        = number
  default     = 300
}

################################################################################
# Dead Letter Queue (Redrive Policy)
################################################################################

variable "redrive_max_receive_count" {
  description = "The number of times a consumer can receive a message before it is sent to the dead letter queue. An integer from 1 to 1000. Only applicable when `create_dlq` is `true`. Default is 5"
  type        = number
  default     = 5
}

################################################################################
# FIFO Queue
################################################################################

variable "fifo_queue" {
  description = "Boolean designating a FIFO queue. If `true`, the queue name must end with the `.fifo` suffix. FIFO queues guarantee exactly-once processing and preserve message order within a message group"
  type        = bool
  default     = false
}

variable "content_based_deduplication" {
  description = "Enables content-based deduplication for FIFO queues. If enabled, Amazon SQS uses a SHA-256 hash of the message body to generate a message deduplication ID. Only applicable when `fifo_queue` is `true`"
  type        = bool
  default     = false
}

variable "deduplication_scope" {
  description = "Specifies whether message deduplication occurs at the message group or queue level. Valid values are `messageGroup` and `queue`. AWS default is `queue`. Only applicable when `fifo_queue` is `true` and high throughput mode is enabled"
  type        = string
  default     = null
}

variable "fifo_throughput_limit" {
  description = "Specifies whether the FIFO queue throughput quota applies to the entire queue or per message group. Valid values are `perQueue` and `perMessageGroupId`. AWS default is `perQueue`. Only applicable when `fifo_queue` is `true`"
  type        = string
  default     = null
}

################################################################################
# Queue Policy
################################################################################

variable "create_queue_policy" {
  description = "Determines whether to create an SQS queue access policy"
  type        = bool
  default     = true
}

variable "sqs_policy" {
  type        = any
  default     = []
  description = <<EOF
List of IAM policy statements for the SQS queue policy. Statements must have unique `sid`s.

Example)
  sqs_policy = [
    {
      Sid       = "AllowRootAccountAccess"
      Effect    = "Allow"
      Principal = { AWS = "arn:aws:iam::123456789012:root" }
      Action    = ["sqs:*"]
      Resource  = "*"
    },
    {
      Sid       = "DenyUnencryptedTransport"
      Effect    = "Deny"
      Principal = { AWS = "*" }
      Action    = ["sqs:*"]
      Resource  = "*"
      Condition = { Bool = { "aws:SecureTransport" = "false" } }
    }
  ]
EOF
}

################################################################################
# Dead Letter Queue
################################################################################

variable "create_dlq" {
  description = "Determines whether to create a Dead Letter Queue (DLQ) for the main SQS queue. When enabled, messages that fail processing are automatically moved to the DLQ after exceeding the `maxReceiveCount` threshold"
  type        = bool
  default     = false
}

variable "dlq_name" {
  description = "This is the human-readable name of the dead letter queue. If omitted, the name will be derived from the main queue name with a `-dlq` suffix. For FIFO queues, the `.fifo` suffix is appended automatically. Ignored when `dlq_fullname` is set"
  type        = string
  default     = null
}

variable "dlq_fullname" {
  description = "The fully qualified name of the dead letter queue. When set, the value is used as-is and overrides the name derived from `dlq_name` and the context naming convention. For FIFO queues, the `.fifo` suffix must be included manually"
  type        = string
  default     = null
}

variable "dlq_delay_seconds" {
  description = "The time in seconds that the delivery of all messages in the dead letter queue will be delayed. An integer from 0 to 900 (15 minutes). If not set, inherits from `delay_seconds`"
  type        = number
  default     = null
}

variable "dlq_message_retention_seconds" {
  description = "The number of seconds Amazon SQS retains a message in the dead letter queue. Integer representing seconds, from 60 (1 minute) to 1209600 (14 days). Default is 1209600 (14 days) to allow sufficient time for investigation and reprocessing"
  type        = number
  default     = 1209600
}

variable "dlq_receive_wait_time_seconds" {
  description = "The time for which a ReceiveMessage call will wait for a message to arrive (long polling) in the dead letter queue. An integer from 0 to 20 (seconds). If not set, inherits from `receive_wait_time_seconds`"
  type        = number
  default     = null
}

variable "dlq_visibility_timeout_seconds" {
  description = "The visibility timeout for the dead letter queue, in seconds. An integer from 0 to 43200 (12 hours). If not set, inherits from `visibility_timeout_seconds`"
  type        = number
  default     = null
}

################################################################################
# Dead Letter Queue - Encryption
################################################################################

variable "dlq_kms_data_key_reuse_period_seconds" {
  description = "The length of time, in seconds, for which Amazon SQS can reuse a data key to encrypt or decrypt messages in the dead letter queue before calling AWS KMS again. An integer between 60 seconds (1 minute) and 86,400 seconds (24 hours). If not set, inherits from `kms_data_key_reuse_period_seconds`"
  type        = number
  default     = null
}

################################################################################
# Dead Letter Queue - FIFO
################################################################################

variable "dlq_content_based_deduplication" {
  description = "Enables content-based deduplication for FIFO dead letter queues. Only applicable when `fifo_queue` is `true`. If not set, inherits from `content_based_deduplication`"
  type        = bool
  default     = null
}

variable "dlq_deduplication_scope" {
  description = "Specifies whether message deduplication occurs at the message group or queue level for the dead letter queue. Valid values are `messageGroup` and `queue`. AWS default is `queue`. Only applicable when `fifo_queue` is `true`"
  type        = string
  default     = null
}

################################################################################
# Dead Letter Queue - Redrive Allow Policy
################################################################################

variable "create_dlq_redrive_allow_policy" {
  description = "Determines whether to create a redrive allow policy for the dead letter queue. When enabled, specifies which source queues can use this queue as a dead letter queue"
  type        = bool
  default     = true
}

variable "dlq_redrive_allow_policy" {
  description = <<EOF
Additional attributes to merge into the Dead Letter Queue redrive allow policy. By default, `redrivePermission` is set to `byQueue` and `sourceQueueArns` is set to the main queue ARN. Use this variable to override those defaults.
See [AWS documentation](https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-dead-letter-queues.html) for details.

Example) Allow any source queue to use this DLQ:
  dlq_redrive_allow_policy = {
    redrivePermission = "allowAll"
  }

Example) Restrict to a specific source queue ARN:
  dlq_redrive_allow_policy = {
    redrivePermission = "byQueue"
    sourceQueueArns   = ["arn:aws:sqs:ap-northeast-2:123456789012:my-source-queue"]
  }
EOF
  type        = any
  default     = null
}

################################################################################
# Dead Letter Queue - Policy
################################################################################

variable "create_dlq_policy" {
  description = "Determines whether to create an access policy for the dead letter queue"
  type        = bool
  default     = false
}

variable "dlq_policy" {
  description = <<EOF
List of IAM policy statements for the dead letter queue policy. Statements must have unique `sid`s.

Example)
  dlq_policy = [
    {
      Sid       = "AllowRootAccountAccess"
      Effect    = "Allow"
      Principal = { AWS = "arn:aws:iam::123456789012:root" }
      Action    = ["sqs:*"]
      Resource  = "*"
    },
    {
      Sid       = "DenyUnencryptedTransport"
      Effect    = "Deny"
      Principal = { AWS = "*" }
      Action    = ["sqs:*"]
      Resource  = "*"
      Condition = { Bool = { "aws:SecureTransport" = "false" } }
    }
  ]
EOF
  type        = any
  default     = []
}

