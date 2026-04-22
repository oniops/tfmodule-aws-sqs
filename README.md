# tfmodule-aws-sqs

tfmodule-aws-sqs is a Terraform module which creates AWS SQS (Simple Queue Service) resources.

## How to clone

```sh
git clone https://github.com/oniops/tfmodule-aws-sqs.git
cd tfmodule-aws-sqs
```

## Context

This module uses the tfmodule-context Terraform module to define SQS services and resources, providing a standardized naming policy and tagging conventions for AWS Best Practice model, and a consistent datasource reference module.
<br>
For more information about Context, see the [tfmodule-context](https://github.com/oniops/tfmodule-context) Terraform module.

## Usage

### Example 1 : Standard SQS Queue

This chapter explains how to create a basic standard SQS queue.

```hcl
module "sqs" {
  source                     = "git::https://github.com/oniops/tfmodule-aws-sqs.git?ref=v1.0.0"
  context                    = module.ctx.context
  sqs_name                   = "my-queue"
  delay_seconds              = 0
  message_retention_seconds  = 345600
  visibility_timeout_seconds = 30
}

output "queue_url" {
  value = module.sqs.queue_url
}

output "queue_arn" {
  value = module.sqs.queue_arn
}
```

<br>

### Example 2 : Standard SQS Queue with Cross-Account IAM Role Access

This chapter explains how to allow an IAM Identity (Role) from another AWS account (`111122223333`) to access the queue using `sqs_policy`.

```hcl
module "sqs" {
  source   = "git::https://github.com/oniops/tfmodule-aws-sqs.git?ref=v1.0.0"
  context  = module.ctx.context
  sqs_name = "my-queue"

  sqs_policy = [
    {
      Sid       = "AllowCrossAccountRoleAccess"
      Effect    = "Allow"
      Principal = {
        AWS = "arn:aws:iam::111122223333:role/my-cross-account-role"
      }
      Action = [
        "sqs:SendMessage",
        "sqs:ReceiveMessage",
        "sqs:DeleteMessage",
        "sqs:GetQueueAttributes"
      ]
      Resource = "arn:aws:sqs:ap-northeast-2:444455556666:my-queue-sqs"
    }
  ]
}
```

<br>

### Example 3 : Standard SQS Queue with SNS / EventBridge Integration

This chapter explains how to allow AWS services (e.g. SNS, EventBridge) to produce or consume messages from the queue using `sqs_access_services`.

```hcl
module "sqs" {
  source   = "git::https://github.com/oniops/tfmodule-aws-sqs.git?ref=v1.0.0"
  context  = module.ctx.context
  sqs_name = "my-queue"

  sqs_access_services = {
    producer = {
      "my-topic" = {
        service = "sns.amazonaws.com"
        arn     = "arn:aws:sns:ap-northeast-2:111122223333:my-topic"
      }
      "my-rule" = {
        service = "events.amazonaws.com"
        arn     = "arn:aws:events:ap-northeast-2:111122223333:rule/my-rule"
      }
    }
    consumer = {
      "my-consumer-rule" = {
        service = "events.amazonaws.com"
        arn     = "arn:aws:events:ap-northeast-2:111122223333:rule/my-consumer-rule"
      }
    }
  }
}
```

<br>

### Example 4 : Standard SQS Queue with Dead Letter Queue (DLQ)

This chapter explains how to create a standard SQS queue with an automatically provisioned Dead Letter Queue. Messages that fail processing are moved to the DLQ after exceeding the `maxReceiveCount` threshold.

```hcl
module "sqs" {
  source   = "git::https://github.com/oniops/tfmodule-aws-sqs.git?ref=v1.0.0"
  context  = module.ctx.context
  sqs_name = "my-queue"

  # Enable Dead Letter Queue
  create_dlq                    = true
  dlq_message_retention_seconds = 1209600  # 14 days

  tags = {
    Service = "my-service"
  }
}

output "queue_url" {
  value = module.sqs.queue_url
}

output "dlq_url" {
  value = module.sqs.dead_letter_queue_url
}
```

<br>

### Example 5 : FIFO Queue

This chapter explains how to create a FIFO (First-In-First-Out) queue that guarantees message ordering and exactly-once processing within a message group.

```hcl
module "sqs" {
  source   = "git::https://github.com/oniops/tfmodule-aws-sqs.git?ref=v1.0.0"
  context  = module.ctx.context
  sqs_name = "my-queue"  # The module automatically appends '-sqs.fifo' suffix

  fifo_queue                  = true
  content_based_deduplication = true
}
```

For high-throughput FIFO queues, set `deduplication_scope` and `fifo_throughput_limit`:

```hcl
module "sqs" {
  source   = "git::https://github.com/oniops/tfmodule-aws-sqs.git?ref=v1.0.0"
  context  = module.ctx.context
  sqs_name = "my-queue"

  fifo_queue            = true
  deduplication_scope   = "messageGroup"
  fifo_throughput_limit = "perMessageGroupId"
}
```

<br>

### Example 6 : Queue with KMS Encryption (SSE-KMS)

This chapter explains how to encrypt queue messages using a customer-managed KMS key instead of the default SQS-managed SSE.

```hcl
module "sqs" {
  source   = "git::https://github.com/oniops/tfmodule-aws-sqs.git?ref=v1.0.0"
  context  = module.ctx.context
  sqs_name = "my-queue"

  # Disable SQS-managed SSE and use customer KMS key instead
  sqs_managed_sse_enabled           = false
  kms_master_key_id                 = "arn:aws:kms:ap-northeast-2:111122223333:key/012ab345-ab12-3344-a556-112233445566"
  kms_data_key_reuse_period_seconds = 300
}
```

<br>

## Variables

This chapter describes Input/Output variables used in tfmodule-aws-sqs.

### Input Variables

<table>
<thead>
    <tr>
        <th>Name</th>
        <th>Description</th>
        <th>Type</th>
        <th>Default</th>
        <th>Required</th>
        <th>Example</th>
    </tr>
</thead>
<tbody>
    <tr>
        <td>context</td>
        <td>Specify context values. This module uses the tfmodule-context Terraform module to define SQS services and resources, providing a standardized naming policy and tagging conventions, and a consistent datasource reference module. For more information about Context, see the <a href="https://github.com/oniops/tfmodule-context">tfmodule-context</a> Terraform module.</td>
        <td>any</td>
        <td></td>
        <td>yes</td>
        <td><pre>{
  project     = "demo"
  region      = "ap-northeast-2"
  environment = "Development"
  department  = "DevOps"
  owner       = "my_devops_team@example.com"
  customer    = "Example Customer"
  domain      = "example.com"
  pri_domain  = "example.internal"
}</pre></td>
    </tr>
    <tr>
        <td>tags</td>
        <td>Specify tags for resources created in this module.</td>
        <td>map(string)</td>
        <td>{}</td>
        <td>no</td>
        <td><pre>{
  ExpirationDate = "20260102"
  PurposeOfUse   = "PoC"
}</pre></td>
    </tr>
    <tr>
        <td>create</td>
        <td>Determines whether SQS queue resources will be created.</td>
        <td>bool</td>
        <td>true</td>
        <td>no</td>
        <td>false</td>
    </tr>
</tbody>
</table>

#### Queue

<table>
<thead>
    <tr>
        <th>Name</th>
        <th>Description</th>
        <th>Type</th>
        <th>Default</th>
        <th>Required</th>
        <th>Example</th>
    </tr>
</thead>
<tbody>
    <tr>
        <td>sqs_name</td>
        <td>Human-readable name of the queue. The module appends <code>-sqs</code> to form the final queue name (e.g. <code>my-queue-sqs</code>). For FIFO queues, <code>-sqs.fifo</code> is appended instead. Ignored when <code>sqs_fullname</code> is set.</td>
        <td>string</td>
        <td>null</td>
        <td>no</td>
        <td>"my-queue"</td>
    </tr>
    <tr>
        <td>sqs_fullname</td>
        <td>Fully qualified name of the queue. When set, the value is used as-is and overrides the name derived from <code>sqs_name</code>. Useful when the queue name must follow a custom format. For FIFO queues, the <code>.fifo</code> suffix must be included manually.</td>
        <td>string</td>
        <td>null</td>
        <td>no</td>
        <td>"my-custom-exact-queue-name"</td>
    </tr>
    <tr>
        <td>delay_seconds</td>
        <td>Time in seconds that the delivery of all messages in the queue will be delayed. An integer from 0 to 900 (15 minutes).</td>
        <td>number</td>
        <td>0</td>
        <td>no</td>
        <td>30</td>
    </tr>
    <tr>
        <td>max_message_size</td>
        <td>The limit of how many bytes a message can contain before Amazon SQS rejects it. An integer from 1024 bytes (1 KiB) up to 262144 bytes (256 KiB).</td>
        <td>number</td>
        <td>262144</td>
        <td>no</td>
        <td>65536</td>
    </tr>
    <tr>
        <td>message_retention_seconds</td>
        <td>The number of seconds Amazon SQS retains a message. Integer from 60 (1 minute) to 1209600 (14 days).</td>
        <td>number</td>
        <td>345600</td>
        <td>no</td>
        <td>86400</td>
    </tr>
    <tr>
        <td>receive_wait_time_seconds</td>
        <td>Time for which a ReceiveMessage call will wait for a message to arrive (long polling). An integer from 0 to 20 (seconds). Setting to a positive value enables long polling.</td>
        <td>number</td>
        <td>0</td>
        <td>no</td>
        <td>20</td>
    </tr>
    <tr>
        <td>visibility_timeout_seconds</td>
        <td>The visibility timeout for the queue in seconds. During this time, a received message is invisible to other consumers. An integer from 0 to 43200 (12 hours).</td>
        <td>number</td>
        <td>30</td>
        <td>no</td>
        <td>60</td>
    </tr>
</tbody>
</table>

#### Encryption

<table>
<thead>
    <tr>
        <th>Name</th>
        <th>Description</th>
        <th>Type</th>
        <th>Default</th>
        <th>Required</th>
        <th>Example</th>
    </tr>
</thead>
<tbody>
    <tr>
        <td>sqs_managed_sse_enabled</td>
        <td>Boolean to enable server-side encryption (SSE) of message content with SQS-owned encryption keys. Mutually exclusive with <code>kms_master_key_id</code>. Must be set to <code>false</code> when using a custom KMS key.</td>
        <td>bool</td>
        <td>true</td>
        <td>no</td>
        <td>false</td>
    </tr>
    <tr>
        <td>kms_master_key_id</td>
        <td>The ID of an AWS-managed customer master key (CMK) for Amazon SQS or a custom CMK. Setting this value enables KMS encryption; <code>sqs_managed_sse_enabled</code> must be set to <code>false</code>.</td>
        <td>string</td>
        <td>null</td>
        <td>no</td>
        <td>"arn:aws:kms:ap-northeast-2:111122223333:key/012ab345-ab12-3344-a556-112233445566"</td>
    </tr>
    <tr>
        <td>kms_data_key_reuse_period_seconds</td>
        <td>Length of time in seconds for which Amazon SQS can reuse a data key to encrypt or decrypt messages before calling AWS KMS again. An integer between 60 (1 minute) and 86400 (24 hours).</td>
        <td>number</td>
        <td>300</td>
        <td>no</td>
        <td>3600</td>
    </tr>
</tbody>
</table>

#### Redrive Policy

<table>
<thead>
    <tr>
        <th>Name</th>
        <th>Description</th>
        <th>Type</th>
        <th>Default</th>
        <th>Required</th>
        <th>Example</th>
    </tr>
</thead>
<tbody>
    <tr>
        <td>redrive_max_receive_count</td>
        <td>The number of times a consumer can receive a message before it is sent to the dead letter queue. An integer from 1 to 1000. Only applicable when <code>create_dlq</code> is <code>true</code>.</td>
        <td>number</td>
        <td>5</td>
        <td>no</td>
        <td>3</td>
    </tr>
</tbody>
</table>

#### FIFO Queue

<table>
<thead>
    <tr>
        <th>Name</th>
        <th>Description</th>
        <th>Type</th>
        <th>Default</th>
        <th>Required</th>
        <th>Example</th>
    </tr>
</thead>
<tbody>
    <tr>
        <td>fifo_queue</td>
        <td>Boolean designating a FIFO queue. FIFO queues guarantee exactly-once processing and preserve message order within a message group. The <code>-sqs.fifo</code> suffix is appended automatically.</td>
        <td>bool</td>
        <td>false</td>
        <td>no</td>
        <td>true</td>
    </tr>
    <tr>
        <td>content_based_deduplication</td>
        <td>Enables content-based deduplication for FIFO queues. Amazon SQS uses a SHA-256 hash of the message body to generate the deduplication ID. Only applicable when <code>fifo_queue</code> is <code>true</code>.</td>
        <td>bool</td>
        <td>false</td>
        <td>no</td>
        <td>true</td>
    </tr>
    <tr>
        <td>deduplication_scope</td>
        <td>Specifies whether message deduplication occurs at the message group or queue level. Valid values are <code>messageGroup</code> and <code>queue</code>. AWS default is <code>queue</code>. Only applicable when <code>fifo_queue</code> is <code>true</code> and high throughput mode is enabled.</td>
        <td>string</td>
        <td>null</td>
        <td>no</td>
        <td>"messageGroup"</td>
    </tr>
    <tr>
        <td>fifo_throughput_limit</td>
        <td>Specifies whether the FIFO queue throughput quota applies to the entire queue or per message group. Valid values are <code>perQueue</code> and <code>perMessageGroupId</code>. AWS default is <code>perQueue</code>. Only applicable when <code>fifo_queue</code> is <code>true</code>.</td>
        <td>string</td>
        <td>null</td>
        <td>no</td>
        <td>"perMessageGroupId"</td>
    </tr>
</tbody>
</table>

#### Queue Policy

<table>
<thead>
    <tr>
        <th>Name</th>
        <th>Description</th>
        <th>Type</th>
        <th>Default</th>
        <th>Required</th>
        <th>Example</th>
    </tr>
</thead>
<tbody>
    <tr>
        <td>create_queue_policy</td>
        <td>Determines whether to create an SQS queue access policy.</td>
        <td>bool</td>
        <td>true</td>
        <td>no</td>
        <td>false</td>
    </tr>
    <tr>
        <td>sqs_access_services</td>
        <td>SQS queue access configuration. Defines producer and/or consumer access as named maps of AWS service principal and resource ARN pairs.</td>
        <td>object</td>
        <td>null</td>
        <td>no</td>
        <td><pre>{
  producer = {
    "my-topic" = {
      service = "sns.amazonaws.com"
      arn     = "arn:aws:sns:ap-northeast-2:111122223333:my-topic"
    }
  }
  consumer = {
    "my-rule" = {
      service = "events.amazonaws.com"
      arn     = "arn:aws:events:ap-northeast-2:111122223333:rule/my-rule"
    }
  }
}</pre></td>
    </tr>
    <tr>
        <td>sqs_policy</td>
        <td>List of additional IAM policy statements to merge into the SQS queue policy alongside statements generated from <code>sqs_access_services</code>. Statements must have unique <code>sid</code>s.</td>
        <td>any</td>
        <td>[]</td>
        <td>no</td>
        <td><pre>[
  {
    Sid       = "AllowRootAccountAccess"
    Effect    = "Allow"
    Principal = { AWS = "arn:aws:iam::123456789012:root" }
    Action    = ["sqs:*"]
    Resource  = "*"
  }
]</pre></td>
    </tr>
</tbody>
</table>

#### Dead Letter Queue

<table>
<thead>
    <tr>
        <th>Name</th>
        <th>Description</th>
        <th>Type</th>
        <th>Default</th>
        <th>Required</th>
        <th>Example</th>
    </tr>
</thead>
<tbody>
    <tr>
        <td>create_dlq</td>
        <td>Determines whether to create a Dead Letter Queue (DLQ) for the main SQS queue. When enabled, messages that fail processing are automatically moved to the DLQ after exceeding the <code>maxReceiveCount</code> threshold.</td>
        <td>bool</td>
        <td>false</td>
        <td>no</td>
        <td>true</td>
    </tr>
    <tr>
        <td>dlq_name</td>
        <td>Human-readable name of the dead letter queue. If omitted, the name is derived from <code>sqs_name</code> with a <code>-dlq-sqs</code> suffix (e.g. <code>my-queue-dlq-sqs</code>). For FIFO queues, <code>-dlq-sqs.fifo</code> is appended instead. Ignored when <code>dlq_fullname</code> is set.</td>
        <td>string</td>
        <td>null</td>
        <td>no</td>
        <td>"my-queue-dlq"</td>
    </tr>
    <tr>
        <td>dlq_fullname</td>
        <td>Fully qualified name of the dead letter queue. When set, the value is used as-is and overrides the name derived from <code>dlq_name</code>. For FIFO queues, the <code>.fifo</code> suffix must be included manually.</td>
        <td>string</td>
        <td>null</td>
        <td>no</td>
        <td>"my-custom-exact-dlq-name"</td>
    </tr>
    <tr>
        <td>dlq_delay_seconds</td>
        <td>Time in seconds that the delivery of all messages in the dead letter queue will be delayed. An integer from 0 to 900 (15 minutes). If not set, inherits from <code>delay_seconds</code>.</td>
        <td>number</td>
        <td>null</td>
        <td>no</td>
        <td>30</td>
    </tr>
    <tr>
        <td>dlq_message_retention_seconds</td>
        <td>The number of seconds Amazon SQS retains a message in the dead letter queue. Integer from 60 (1 minute) to 1209600 (14 days). Default is 14 days to allow sufficient time for investigation and reprocessing.</td>
        <td>number</td>
        <td>1209600</td>
        <td>no</td>
        <td>604800</td>
    </tr>
    <tr>
        <td>dlq_receive_wait_time_seconds</td>
        <td>Time for which a ReceiveMessage call will wait for a message to arrive in the dead letter queue. An integer from 0 to 20 (seconds). If not set, inherits from <code>receive_wait_time_seconds</code>.</td>
        <td>number</td>
        <td>null</td>
        <td>no</td>
        <td>20</td>
    </tr>
    <tr>
        <td>dlq_visibility_timeout_seconds</td>
        <td>The visibility timeout for the dead letter queue in seconds. An integer from 0 to 43200 (12 hours). If not set, inherits from <code>visibility_timeout_seconds</code>.</td>
        <td>number</td>
        <td>null</td>
        <td>no</td>
        <td>60</td>
    </tr>
    <tr>
        <td>dlq_kms_data_key_reuse_period_seconds</td>
        <td>Length of time in seconds for which Amazon SQS can reuse a data key to encrypt or decrypt messages in the dead letter queue. An integer between 60 (1 minute) and 86400 (24 hours). If not set, inherits from <code>kms_data_key_reuse_period_seconds</code>.</td>
        <td>number</td>
        <td>null</td>
        <td>no</td>
        <td>3600</td>
    </tr>
    <tr>
        <td>dlq_content_based_deduplication</td>
        <td>Enables content-based deduplication for FIFO dead letter queues. Only applicable when <code>fifo_queue</code> is <code>true</code>. If not set, inherits from <code>content_based_deduplication</code>.</td>
        <td>bool</td>
        <td>null</td>
        <td>no</td>
        <td>true</td>
    </tr>
    <tr>
        <td>dlq_deduplication_scope</td>
        <td>Specifies whether message deduplication occurs at the message group or queue level for the dead letter queue. Valid values are <code>messageGroup</code> and <code>queue</code>. AWS default is <code>queue</code>. Only applicable when <code>fifo_queue</code> is <code>true</code>.</td>
        <td>string</td>
        <td>null</td>
        <td>no</td>
        <td>"messageGroup"</td>
    </tr>
    <tr>
        <td>create_dlq_redrive_allow_policy</td>
        <td>Determines whether to create a redrive allow policy for the dead letter queue. When enabled, specifies which source queues can use this queue as a dead letter queue.</td>
        <td>bool</td>
        <td>true</td>
        <td>no</td>
        <td>false</td>
    </tr>
    <tr>
        <td>dlq_redrive_allow_policy</td>
        <td>Additional attributes to merge into the Dead Letter Queue redrive allow policy. By default, <code>redrivePermission</code> is set to <code>byQueue</code> and <code>sourceQueueArns</code> is set to the main queue ARN. Use this variable to override those defaults.</td>
        <td>any</td>
        <td>null</td>
        <td>no</td>
        <td><pre>Allow any source queue to use this DLQ:
{
  redrivePermission = "allowAll"
}
Restrict to a specific source queue ARN:
{
  redrivePermission = "byQueue"
  sourceQueueArns   = [
    "arn:aws:sqs:ap-northeast-2:111122223333:source-queue"
  ]
}</pre></td>
    </tr>
    <tr>
        <td>create_dlq_policy</td>
        <td>Determines whether to create an access policy for the dead letter queue.</td>
        <td>bool</td>
        <td>false</td>
        <td>no</td>
        <td>true</td>
    </tr>
    <tr>
        <td>dlq_policy</td>
        <td>List of additional IAM policy statements to merge into the dead letter queue policy alongside statements generated from <code>dlq_access_services</code>. Statements must have unique <code>sid</code>s.</td>
        <td>any</td>
        <td>[]</td>
        <td>no</td>
        <td><pre>[
  {
    Sid       = "AllowRootAccountAccess"
    Effect    = "Allow"
    Principal = { AWS = "arn:aws:iam::123456789012:root" }
    Action    = ["sqs:*"]
    Resource  = "*"
  }
]</pre></td>
    </tr>
    <tr>
        <td>dlq_access_services</td>
        <td>Dead Letter Queue access configuration. Defines producer and/or consumer access as named maps of AWS service principal and resource ARN pairs.</td>
        <td>object</td>
        <td>null</td>
        <td>no</td>
        <td><pre>{
  producer = {
    "my-topic" = {
      service = "sns.amazonaws.com"
      arn     = "arn:aws:sns:ap-northeast-2:111122223333:my-topic"
    }
  }
  consumer = {
    "my-rule" = {
      service = "events.amazonaws.com"
      arn     = "arn:aws:events:ap-northeast-2:111122223333:rule/my-rule"
    }
  }
}</pre></td>
    </tr>
</tbody>
</table>

### Output Variables

<table>
<thead>
    <tr>
        <th>Name</th>
        <th>Description</th>
        <th>Type</th>
        <th>Example</th>
    </tr>
</thead>
<tbody>
    <tr>
        <td>queue_arn</td>
        <td>The ARN of the SQS queue.</td>
        <td>string</td>
        <td>"arn:aws:sqs:ap-northeast-2:111122223333:my-queue-sqs"</td>
    </tr>
    <tr>
        <td>queue_url</td>
        <td>The URL for the created Amazon SQS queue.</td>
        <td>string</td>
        <td>"https://sqs.ap-northeast-2.amazonaws.com/111122223333/my-queue-sqs"</td>
    </tr>
    <tr>
        <td>queue_name</td>
        <td>The name of the SQS queue.</td>
        <td>string</td>
        <td>"my-queue-sqs"</td>
    </tr>
    <tr>
        <td>dead_letter_queue_arn</td>
        <td>The ARN of the SQS dead letter queue.</td>
        <td>string</td>
        <td>"arn:aws:sqs:ap-northeast-2:111122223333:my-queue-dlq-sqs"</td>
    </tr>
    <tr>
        <td>dead_letter_queue_url</td>
        <td>The URL for the created Amazon SQS dead letter queue.</td>
        <td>string</td>
        <td>"https://sqs.ap-northeast-2.amazonaws.com/111122223333/my-queue-dlq-sqs"</td>
    </tr>
    <tr>
        <td>dead_letter_queue_name</td>
        <td>The name of the SQS dead letter queue.</td>
        <td>string</td>
        <td>"my-queue-dlq-sqs"</td>
    </tr>
</tbody>
</table>

# Appendix

## AWS SQS Overview

Amazon SQS (Simple Queue Service) is a fully managed message queuing service that supports decoupling and scaling of microservices, distributed systems, and serverless applications. It acts as a reliable message buffer between producers and consumers, and supports both Standard and FIFO queues.
<br>
For more information : [Amazon Simple Queue Service](https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/welcome.html)

### Dead Letter Queue (DLQ)

A Dead Letter Queue is a special queue that isolates messages that have failed processing. Messages that fail processing more than `maxReceiveCount` times are automatically moved to the DLQ, providing the following benefits.

- **Failure Isolation**: Failed messages are not re-entered into the main queue, maintaining service stability.
- **Easy Debugging**: Messages are retained for an extended period (default 14 days) for failure analysis and reprocessing.
- **Alarm Integration**: CloudWatch alarms on DLQ message count enable immediate detection of processing failures.

### Encryption (SSE)

SQS supports two server-side encryption (SSE) methods.

| Method | Description | Variable |
|--------|-------------|----------|
| SSE-SQS | Encrypted with SQS-managed keys. No additional cost. | `sqs_managed_sse_enabled = true` |
| SSE-KMS | Encrypted with customer-managed KMS keys. Fine-grained control over key access policies. | `kms_master_key_id = "<key-arn>"` |

> **Note**: `sqs_managed_sse_enabled` and `kms_master_key_id` are mutually exclusive. When using a KMS key, `sqs_managed_sse_enabled` must be set to `false`.

### Queue Policy and sqs_access_services

Using the `sqs_access_services` variable automatically generates IAM policies that allow AWS service principals to produce or consume messages from the queue.

```hcl
sqs_access_services = {
  producer = {
    # Allows SNS to produce messages
    "my-topic" = {
      service = "sns.amazonaws.com"
      arn     = "arn:aws:sns:ap-northeast-2:111122223333:my-topic"
    }
    # Allows EventBridge to produce messages
    "my-rule" = {
      service = "events.amazonaws.com"
      arn     = "arn:aws:events:ap-northeast-2:111122223333:rule/my-rule"
    }
  }
}
```

Generated policy actions:
- **Producer** (`producer`): `sqs:SendMessage`
- **Consumer** (`consumer`): `sqs:ReceiveMessage`, `sqs:DeleteMessage`, `sqs:GetQueueAttributes`, `sqs:ChangeMessageVisibility`

# LICENSE

- See [LICENSE](https://github.com/oniops/tfmodule-aws-sqs/blob/main/LICENSE) for Apache-2.0.
