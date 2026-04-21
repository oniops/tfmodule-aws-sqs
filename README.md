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
module "ctx" {
  source = "git::https://github.com/oniops/tfmodule-context.git?ref=v1.3.3"
  context = {
    project     = "demo"
    region      = "ap-northeast-2"
    environment = "Development"
    department  = "DevOps"
    owner       = "my_devops_team@example.com"
    customer    = "Example Customer"
    domain      = "example.com"
    pri_domain  = "example.internal"
  }
}

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

### Example 2 : Standard SQS Queue with SNS / EventBridge Integration

This chapter explains how to allow AWS services (e.g. SNS, EventBridge) to produce or consume messages from the queue using `sqs_access_services`.

```hcl
module "ctx" {
  source = "git::https://github.com/oniops/tfmodule-context.git?ref=v1.3.3"
  context = {
    project     = "demo"
    region      = "ap-northeast-2"
    environment = "Development"
    department  = "DevOps"
    owner       = "my_devops_team@example.com"
    customer    = "Example Customer"
    domain      = "example.com"
    pri_domain  = "example.internal"
  }
}

module "sqs" {
  source   = "git::https://github.com/oniops/tfmodule-aws-sqs.git?ref=v1.0.0"
  context  = module.ctx.context
  sqs_name = "my-queue"

  sqs_access_services = {
    "sns.amazonaws.com" = {
      producer_arns = ["arn:aws:sns:ap-northeast-2:111122223333:my-topic"]
    }
    "events.amazonaws.com" = {
      producer_arns = ["arn:aws:events:ap-northeast-2:111122223333:rule/my-rule"]
    }
  }
}
```

<br>

### Example 3 : Standard SQS Queue with Dead Letter Queue (DLQ)

This chapter explains how to create a standard SQS queue with an automatically provisioned Dead Letter Queue. Messages that fail processing are moved to the DLQ after exceeding the `maxReceiveCount` threshold.

```hcl
module "ctx" {
  source = "git::https://github.com/oniops/tfmodule-context.git?ref=v1.3.3"
  context = {
    project     = "demo"
    region      = "ap-northeast-2"
    environment = "Development"
    department  = "DevOps"
    owner       = "my_devops_team@example.com"
    customer    = "Example Customer"
    domain      = "example.com"
    pri_domain  = "example.internal"
  }
}

module "sqs" {
  source   = "git::https://github.com/oniops/tfmodule-aws-sqs.git?ref=v1.0.0"
  context  = module.ctx.context
  sqs_name = "my-queue"

  # Enable Dead Letter Queue
  create_dlq                    = true
  dlq_message_retention_seconds = 1209600  # 14 days

  additional_tags = {
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

### Example 4 : FIFO Queue

This chapter explains how to create a FIFO (First-In-First-Out) queue that guarantees message ordering and exactly-once processing within a message group.

```hcl
module "ctx" {
  source = "git::https://github.com/oniops/tfmodule-context.git?ref=v1.3.3"
  context = {
    project     = "demo"
    region      = "ap-northeast-2"
    environment = "Development"
    department  = "DevOps"
    owner       = "my_devops_team@example.com"
    customer    = "Example Customer"
    domain      = "example.com"
    pri_domain  = "example.internal"
  }
}

module "sqs" {
  source   = "git::https://github.com/oniops/tfmodule-aws-sqs.git?ref=v1.0.0"
  context  = module.ctx.context
  sqs_name = "my-queue"  # The module automatically appends '.fifo' suffix

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

### Example 5 : Queue with KMS Encryption (SSE-KMS)

This chapter explains how to encrypt queue messages using a customer-managed KMS key instead of the default SQS-managed SSE.

```hcl
module "ctx" {
  source = "git::https://github.com/oniops/tfmodule-context.git?ref=v1.3.3"
  context = {
    project     = "demo"
    region      = "ap-northeast-2"
    environment = "Development"
    department  = "DevOps"
    owner       = "my_devops_team@example.com"
    customer    = "Example Customer"
    domain      = "example.com"
    pri_domain  = "example.internal"
  }
}

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
        <td><pre>
{
  project     = "demo"
  region      = "ap-northeast-2"
  environment = "Development"
  department  = "DevOps"
  owner       = "my_devops_team@example.com"
  customer    = "Example Customer"
  domain      = "example.com"
  pri_domain  = "example.internal"
}
        </pre></td>
    </tr>
    <tr>
        <td>additional_tags</td>
        <td>Specify additional tags for resources created in this module.</td>
        <td>map(string)</td>
        <td>{}</td>
        <td>no</td>
        <td><pre>
{
  ExpirationDate = "20260102"
  PurposeOfUse   = "PoC"
}
        </pre></td>
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
        <td>Human-readable name of the queue. If omitted, the name is derived from the context naming convention. For FIFO queues, the module automatically appends the <code>.fifo</code> suffix. Ignored when <code>sqs_fullname</code> is set.</td>
        <td>string</td>
        <td>null</td>
        <td>no</td>
        <td>"my-queue"</td>
    </tr>
    <tr>
        <td>sqs_fullname</td>
        <td>Fully qualified name of the queue. When set, the value is used as-is and overrides the name derived from <code>sqs_name</code> and the context naming convention. Useful when the queue name must follow a custom format. For FIFO queues, the <code>.fifo</code> suffix must be included manually.</td>
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
        <td>Boolean designating a FIFO queue. FIFO queues guarantee exactly-once processing and preserve message order within a message group. The <code>.fifo</code> suffix is appended automatically.</td>
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
        <td>Map of AWS service principals to SQS access configuration. Key is service principal (e.g. <code>sns.amazonaws.com</code>), value defines which resource ARNs are allowed to produce or consume.</td>
        <td>map(object)</td>
        <td>null</td>
        <td>no</td>
        <td><pre>
{
  "sns.amazonaws.com" = {
    producer_arns = [
      "arn:aws:sns:ap-northeast-2:111122223333:my-topic"
    ]
  }
  "events.amazonaws.com" = {
    producer_arns = [
      "arn:aws:events:ap-northeast-2:111122223333:rule/my-rule"
    ]
    consumer_arns = [
      "arn:aws:events:ap-northeast-2:111122223333:rule/other-rule"
    ]
  }
}
        </pre></td>
    </tr>
    <tr>
        <td>sqs_policy</td>
        <td>List of additional IAM policy statements to merge into the SQS queue policy alongside statements generated from <code>sqs_access_services</code>. Statements must have unique <code>sid</code>s.</td>
        <td>list(any)</td>
        <td>[]</td>
        <td>no</td>
        <td><pre>
[
  {
    Sid       = "AllowRootAccountAccess"
    Effect    = "Allow"
    Principal = { AWS = "arn:aws:iam::123456789012:root" }
    Action    = ["sqs:*"]
    Resource  = "*"
  }
]
        </pre></td>
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
        <td>Human-readable name of the dead letter queue. If omitted, the name is derived from the main queue name with a <code>-dlq</code> suffix. For FIFO queues, the <code>.fifo</code> suffix is appended automatically. Ignored when <code>dlq_fullname</code> is set.</td>
        <td>string</td>
        <td>null</td>
        <td>no</td>
        <td>"my-queue-dlq"</td>
    </tr>
    <tr>
        <td>dlq_fullname</td>
        <td>Fully qualified name of the dead letter queue. When set, the value is used as-is and overrides the name derived from <code>dlq_name</code> and the context naming convention. For FIFO queues, the <code>.fifo</code> suffix must be included manually.</td>
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
        <td><pre>
# Allow any source queue to use this DLQ:
{
  redrivePermission = "allowAll"
}

# Restrict to a specific source queue ARN:
{
  redrivePermission = "byQueue"
  sourceQueueArns   = [
    "arn:aws:sqs:ap-northeast-2:111122223333:source-queue"
  ]
}
        </pre></td>
    </tr>
    <tr>
        <td>create_dlq_queue_policy</td>
        <td>Determines whether to create an access policy for the dead letter queue.</td>
        <td>bool</td>
        <td>false</td>
        <td>no</td>
        <td>true</td>
    </tr>
    <tr>
        <td>dlq_policy</td>
        <td>List of additional IAM policy statements to merge into the dead letter queue policy alongside statements generated from <code>dlq_access_services</code>. Statements must have unique <code>sid</code>s.</td>
        <td>list(any)</td>
        <td>[]</td>
        <td>no</td>
        <td><pre>
[
  {
    Sid       = "AllowRootAccountAccess"
    Effect    = "Allow"
    Principal = { AWS = "arn:aws:iam::123456789012:root" }
    Action    = ["sqs:*"]
    Resource  = "*"
  }
]
        </pre></td>
    </tr>
    <tr>
        <td>dlq_access_services</td>
        <td>Map of AWS service principals to dead-letter SQS access configuration. Key is service principal (e.g. <code>sns.amazonaws.com</code>), value defines which resource ARNs are allowed to produce or consume.</td>
        <td>map(object)</td>
        <td>null</td>
        <td>no</td>
        <td><pre>
{
  "sns.amazonaws.com" = {
    producer_arns = [
      "arn:aws:sns:ap-northeast-2:111122223333:my-topic"
    ]
  }
}
        </pre></td>
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
        <td>queue_id</td>
        <td>The URL for the created Amazon SQS queue. Same as <code>queue_url</code>.</td>
        <td>string</td>
        <td>"https://sqs.ap-northeast-2.amazonaws.com/111122223333/my-queue"</td>
    </tr>
    <tr>
        <td>queue_arn</td>
        <td>The ARN of the SQS queue.</td>
        <td>string</td>
        <td>"arn:aws:sqs:ap-northeast-2:111122223333:my-queue"</td>
    </tr>
    <tr>
        <td>queue_url</td>
        <td>The URL for the created Amazon SQS queue.</td>
        <td>string</td>
        <td>"https://sqs.ap-northeast-2.amazonaws.com/111122223333/my-queue"</td>
    </tr>
    <tr>
        <td>queue_name</td>
        <td>The name of the SQS queue.</td>
        <td>string</td>
        <td>"my-queue"</td>
    </tr>
    <tr>
        <td>dead_letter_queue_id</td>
        <td>The URL for the created Amazon SQS dead letter queue. Same as <code>dead_letter_queue_url</code>.</td>
        <td>string</td>
        <td>"https://sqs.ap-northeast-2.amazonaws.com/111122223333/my-queue-dlq"</td>
    </tr>
    <tr>
        <td>dead_letter_queue_arn</td>
        <td>The ARN of the SQS dead letter queue.</td>
        <td>string</td>
        <td>"arn:aws:sqs:ap-northeast-2:111122223333:my-queue-dlq"</td>
    </tr>
    <tr>
        <td>dead_letter_queue_url</td>
        <td>The URL for the created Amazon SQS dead letter queue.</td>
        <td>string</td>
        <td>"https://sqs.ap-northeast-2.amazonaws.com/111122223333/my-queue-dlq"</td>
    </tr>
    <tr>
        <td>dead_letter_queue_name</td>
        <td>The name of the SQS dead letter queue.</td>
        <td>string</td>
        <td>"my-queue-dlq"</td>
    </tr>
</tbody>
</table>

# Appendix

## AWS SQS 개요

Amazon SQS(Simple Queue Service)는 마이크로서비스, 분산 시스템, 서버리스 애플리케이션의 디커플링 및 스케일링을 지원하는 완전 관리형 메시지 대기열 서비스입니다. 프로듀서와 컨슈머 사이에서 안정적인 메시지 버퍼 역할을 하며, Standard 및 FIFO 큐를 지원합니다.

### 큐 유형 비교

<table>
<thead>
<tr>
    <th>특징</th>
    <th>Standard Queue</th>
    <th>FIFO Queue</th>
</tr>
</thead>
<tbody>
<tr>
    <td>처리량</td>
    <td>무제한 (거의 무한대)</td>
    <td>초당 최대 3,000 메시지 (배치) / 300 메시지 (단건)</td>
</tr>
<tr>
    <td>메시지 순서</td>
    <td>Best-effort 순서 (보장 안 됨)</td>
    <td>메시지 그룹 내 엄격한 순서 보장</td>
</tr>
<tr>
    <td>중복 처리</td>
    <td>At-least-once (중복 가능)</td>
    <td>Exactly-once (중복 없음)</td>
</tr>
<tr>
    <td>사용 사례</td>
    <td>높은 처리량이 필요한 비동기 작업</td>
    <td>순서와 정확성이 중요한 금융/주문 처리</td>
</tr>
</tbody>
</table>

### Dead Letter Queue (DLQ)

Dead Letter Queue는 처리에 실패한 메시지를 격리하는 특수 큐입니다. `maxReceiveCount` 횟수 이상 처리에 실패한 메시지가 자동으로 DLQ로 이동하며, 다음과 같은 이점을 제공합니다.

- **장애 격리**: 처리 실패 메시지가 정상 큐에 재유입되지 않아 서비스 안정성을 유지합니다.
- **디버깅 용이성**: 실패 원인 분석 및 재처리를 위해 메시지를 장기 보관합니다 (기본 14일).
- **알람 연동**: DLQ 메시지 수에 대한 CloudWatch 알람을 통해 처리 실패를 즉시 감지할 수 있습니다.

### 암호화 (SSE)

SQS는 두 가지 서버 측 암호화(SSE) 방식을 지원합니다.

| 방식 | 설명 | 변수 |
|------|------|------|
| SSE-SQS | SQS 관리형 키로 암호화. 추가 비용 없음 | `sqs_managed_sse_enabled = true` |
| SSE-KMS | 고객 관리형 KMS 키로 암호화. 키 접근 정책 세밀 제어 가능 | `kms_master_key_id = "<key-arn>"` |

> **주의**: `sqs_managed_sse_enabled`와 `kms_master_key_id`는 상호 배타적입니다. KMS 키를 사용할 경우 `sqs_managed_sse_enabled = false`로 설정해야 합니다.

### Queue Policy와 sqs_access_services

`sqs_access_services` 변수를 사용하면 AWS 서비스 프린시펄이 큐에 메시지를 발행(produce)하거나 수신(consume)할 수 있는 IAM 정책이 자동으로 생성됩니다.

```hcl
sqs_access_services = {
  # SNS가 메시지 발행 가능
  "sns.amazonaws.com" = {
    producer_arns = ["arn:aws:sns:ap-northeast-2:111122223333:my-topic"]
  }
  # EventBridge가 메시지 발행 가능
  "events.amazonaws.com" = {
    producer_arns = ["arn:aws:events:ap-northeast-2:111122223333:rule/my-rule"]
  }
}
```

생성되는 정책 액션:
- **Producer** (`producer_arns`): `sqs:SendMessage`
- **Consumer** (`consumer_arns`): `sqs:ReceiveMessage`, `sqs:DeleteMessage`, `sqs:GetQueueAttributes`, `sqs:ChangeMessageVisibility`

# LICENSE

- See [LICENSE](https://github.com/oniops/tfmodule-aws-sqs/blob/main/LICENSE) for Apache-2.0.
