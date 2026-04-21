# tfmodule-aws-sqs

tfmodule-aws-sqs는 AWS SQS(Simple Queue Service) 리소스를 생성하는 Terraform 모듈입니다.

## How to clone

```sh
git clone https://github.com/oniops/tfmodule-aws-sqs.git
cd tfmodule-aws-sqs
```

## Context

이 모듈은 tfmodule-context Terraform 모듈을 사용하여 SQS 서비스 및 리소스를 정의합니다. AWS Best Practice 모델에 따른 표준화된 네이밍 정책과 태그 규칙, 일관된 데이터소스 참조 모듈을 제공합니다.
<br>
Context에 대한 자세한 내용은 [tfmodule-context](https://github.com/oniops/tfmodule-context) Terraform 모듈을 참고하세요.

## 사용법

### 예제 1 : 기본 Standard SQS 큐

기본적인 Standard SQS 큐를 생성하는 방법을 설명합니다.

```hcl
module "ctx" {
  source = "git::https://github.com/oniops/tfmodule-context.git?ref=v1.3.5"
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

### 예제 2 : SNS / EventBridge 연동 Standard SQS 큐

`sqs_access_services`를 사용하여 SNS, EventBridge 등 AWS 서비스가 큐에 메시지를 발행하거나 수신할 수 있도록 허용하는 방법을 설명합니다.

```hcl
module "ctx" {
  source = "git::https://github.com/oniops/tfmodule-context.git?ref=v1.3.5"
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

### 예제 3 : Dead Letter Queue (DLQ) 포함 Standard SQS 큐

Dead Letter Queue가 자동으로 프로비저닝되는 Standard SQS 큐를 생성하는 방법을 설명합니다. `maxReceiveCount` 임계값을 초과하여 처리에 실패한 메시지는 DLQ로 이동합니다.

```hcl
module "ctx" {
  source = "git::https://github.com/oniops/tfmodule-context.git?ref=v1.3.5"
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

  # Dead Letter Queue 활성화
  create_dlq                    = true
  dlq_message_retention_seconds = 1209600  # 14일

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

### 예제 4 : FIFO 큐

메시지 그룹 내에서 메시지 순서와 정확히 한 번 처리를 보장하는 FIFO(First-In-First-Out) 큐를 생성하는 방법을 설명합니다.

```hcl
module "ctx" {
  source = "git::https://github.com/oniops/tfmodule-context.git?ref=v1.3.5"
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
  sqs_name = "my-queue"  # 모듈이 자동으로 '-sqs.fifo' 접미사를 추가합니다

  fifo_queue                  = true
  content_based_deduplication = true
}
```

고처리량 FIFO 큐의 경우 `deduplication_scope`와 `fifo_throughput_limit`을 설정합니다:

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

### 예제 5 : KMS 암호화 큐 (SSE-KMS)

기본 SQS 관리형 SSE 대신 고객 관리형 KMS 키를 사용하여 큐 메시지를 암호화하는 방법을 설명합니다.

```hcl
module "ctx" {
  source = "git::https://github.com/oniops/tfmodule-context.git?ref=v1.3.5"
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

  # SQS 관리형 SSE를 비활성화하고 고객 KMS 키 사용
  sqs_managed_sse_enabled           = false
  kms_master_key_id                 = "arn:aws:kms:ap-northeast-2:111122223333:key/012ab345-ab12-3344-a556-112233445566"
  kms_data_key_reuse_period_seconds = 300
}
```

<br>

## 변수

tfmodule-aws-sqs에서 사용되는 입력/출력 변수를 설명합니다.

### 입력 변수

<table>
<thead>
    <tr>
        <th>이름</th>
        <th>설명</th>
        <th>타입</th>
        <th>기본값</th>
        <th>필수</th>
        <th>예시</th>
    </tr>
</thead>
<tbody>
    <tr>
        <td>context</td>
        <td>Context 값을 지정합니다. 이 모듈은 tfmodule-context Terraform 모듈을 사용하여 SQS 서비스 및 리소스를 정의하며, 표준화된 네이밍 정책, 태그 규칙, 일관된 데이터소스 참조 모듈을 제공합니다. Context에 대한 자세한 내용은 <a href="https://github.com/oniops/tfmodule-context">tfmodule-context</a> Terraform 모듈을 참고하세요.</td>
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
        <td>additional_tags</td>
        <td>이 모듈에서 생성되는 리소스에 추가할 태그를 지정합니다.</td>
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
        <td>SQS 큐 리소스 생성 여부를 결정합니다.</td>
        <td>bool</td>
        <td>true</td>
        <td>no</td>
        <td>false</td>
    </tr>
</tbody>
</table>

#### 큐 (Queue)

<table>
<thead>
    <tr>
        <th>이름</th>
        <th>설명</th>
        <th>타입</th>
        <th>기본값</th>
        <th>필수</th>
        <th>예시</th>
    </tr>
</thead>
<tbody>
    <tr>
        <td>sqs_name</td>
        <td>큐의 이름입니다. 모듈이 <code>-sqs</code>를 붙여 최종 큐 이름을 생성합니다 (예: <code>my-queue-sqs</code>). FIFO 큐의 경우 <code>-sqs.fifo</code>가 붙습니다. <code>sqs_fullname</code>이 설정된 경우 무시됩니다.</td>
        <td>string</td>
        <td>null</td>
        <td>no</td>
        <td>"my-queue"</td>
    </tr>
    <tr>
        <td>sqs_fullname</td>
        <td>큐의 전체 이름입니다. 설정하면 해당 값을 그대로 사용하며 <code>sqs_name</code>에서 파생된 이름을 덮어씁니다. 커스텀 형식이 필요할 때 유용합니다. FIFO 큐의 경우 <code>.fifo</code> 접미사를 직접 포함해야 합니다.</td>
        <td>string</td>
        <td>null</td>
        <td>no</td>
        <td>"my-custom-exact-queue-name"</td>
    </tr>
    <tr>
        <td>delay_seconds</td>
        <td>큐의 모든 메시지 전달이 지연되는 시간(초)입니다. 0에서 900(15분) 사이의 정수입니다.</td>
        <td>number</td>
        <td>0</td>
        <td>no</td>
        <td>30</td>
    </tr>
    <tr>
        <td>max_message_size</td>
        <td>Amazon SQS가 거부하기 전 메시지가 포함할 수 있는 최대 바이트 수입니다. 1024바이트(1KiB)에서 262144바이트(256KiB) 사이의 정수입니다.</td>
        <td>number</td>
        <td>262144</td>
        <td>no</td>
        <td>65536</td>
    </tr>
    <tr>
        <td>message_retention_seconds</td>
        <td>Amazon SQS가 메시지를 보관하는 시간(초)입니다. 60(1분)에서 1209600(14일) 사이의 정수입니다.</td>
        <td>number</td>
        <td>345600</td>
        <td>no</td>
        <td>86400</td>
    </tr>
    <tr>
        <td>receive_wait_time_seconds</td>
        <td>ReceiveMessage 호출이 메시지 도착을 기다리는 시간(초, 롱 폴링)입니다. 0에서 20(초) 사이의 정수입니다. 양수 값으로 설정하면 롱 폴링이 활성화됩니다.</td>
        <td>number</td>
        <td>0</td>
        <td>no</td>
        <td>20</td>
    </tr>
    <tr>
        <td>visibility_timeout_seconds</td>
        <td>큐의 가시성 타임아웃(초)입니다. 이 시간 동안 수신된 메시지는 다른 컨슈머에게 보이지 않습니다. 0에서 43200(12시간) 사이의 정수입니다.</td>
        <td>number</td>
        <td>30</td>
        <td>no</td>
        <td>60</td>
    </tr>
</tbody>
</table>

#### 암호화 (Encryption)

<table>
<thead>
    <tr>
        <th>이름</th>
        <th>설명</th>
        <th>타입</th>
        <th>기본값</th>
        <th>필수</th>
        <th>예시</th>
    </tr>
</thead>
<tbody>
    <tr>
        <td>sqs_managed_sse_enabled</td>
        <td>SQS 관리형 암호화 키로 메시지 내용의 서버 측 암호화(SSE)를 활성화하는 Boolean입니다. <code>kms_master_key_id</code>와 상호 배타적입니다. 커스텀 KMS 키를 사용할 경우 <code>false</code>로 설정해야 합니다.</td>
        <td>bool</td>
        <td>true</td>
        <td>no</td>
        <td>false</td>
    </tr>
    <tr>
        <td>kms_master_key_id</td>
        <td>Amazon SQS용 AWS 관리형 CMK 또는 커스텀 CMK의 ID입니다. 이 값을 설정하면 KMS 암호화가 활성화되며 <code>sqs_managed_sse_enabled</code>를 <code>false</code>로 설정해야 합니다.</td>
        <td>string</td>
        <td>null</td>
        <td>no</td>
        <td>"arn:aws:kms:ap-northeast-2:111122223333:key/012ab345-ab12-3344-a556-112233445566"</td>
    </tr>
    <tr>
        <td>kms_data_key_reuse_period_seconds</td>
        <td>Amazon SQS가 AWS KMS를 다시 호출하기 전에 데이터 키를 재사용하여 메시지를 암호화/복호화할 수 있는 시간(초)입니다. 60(1분)에서 86400(24시간) 사이의 정수입니다.</td>
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
        <th>이름</th>
        <th>설명</th>
        <th>타입</th>
        <th>기본값</th>
        <th>필수</th>
        <th>예시</th>
    </tr>
</thead>
<tbody>
    <tr>
        <td>redrive_max_receive_count</td>
        <td>Dead Letter Queue로 전송되기 전 컨슈머가 메시지를 수신할 수 있는 횟수입니다. 1에서 1000 사이의 정수입니다. <code>create_dlq</code>가 <code>true</code>인 경우에만 적용됩니다.</td>
        <td>number</td>
        <td>5</td>
        <td>no</td>
        <td>3</td>
    </tr>
</tbody>
</table>

#### FIFO 큐

<table>
<thead>
    <tr>
        <th>이름</th>
        <th>설명</th>
        <th>타입</th>
        <th>기본값</th>
        <th>필수</th>
        <th>예시</th>
    </tr>
</thead>
<tbody>
    <tr>
        <td>fifo_queue</td>
        <td>FIFO 큐를 지정하는 Boolean입니다. FIFO 큐는 메시지 그룹 내에서 정확히 한 번 처리와 메시지 순서를 보장합니다. <code>-sqs.fifo</code> 접미사는 자동으로 추가됩니다.</td>
        <td>bool</td>
        <td>false</td>
        <td>no</td>
        <td>true</td>
    </tr>
    <tr>
        <td>content_based_deduplication</td>
        <td>FIFO 큐에 대한 콘텐츠 기반 중복 제거를 활성화합니다. Amazon SQS가 메시지 본문의 SHA-256 해시를 사용하여 중복 제거 ID를 생성합니다. <code>fifo_queue</code>가 <code>true</code>인 경우에만 적용됩니다.</td>
        <td>bool</td>
        <td>false</td>
        <td>no</td>
        <td>true</td>
    </tr>
    <tr>
        <td>deduplication_scope</td>
        <td>메시지 중복 제거가 메시지 그룹 수준 또는 큐 수준에서 발생하는지 지정합니다. 유효한 값은 <code>messageGroup</code>과 <code>queue</code>입니다. AWS 기본값은 <code>queue</code>입니다. <code>fifo_queue</code>가 <code>true</code>이고 고처리량 모드가 활성화된 경우에만 적용됩니다.</td>
        <td>string</td>
        <td>null</td>
        <td>no</td>
        <td>"messageGroup"</td>
    </tr>
    <tr>
        <td>fifo_throughput_limit</td>
        <td>FIFO 큐 처리량 할당량을 전체 큐 또는 메시지 그룹 단위로 적용할지 지정합니다. 유효한 값은 <code>perQueue</code>와 <code>perMessageGroupId</code>입니다. AWS 기본값은 <code>perQueue</code>입니다. <code>fifo_queue</code>가 <code>true</code>인 경우에만 적용됩니다.</td>
        <td>string</td>
        <td>null</td>
        <td>no</td>
        <td>"perMessageGroupId"</td>
    </tr>
</tbody>
</table>

#### 큐 정책 (Queue Policy)

<table>
<thead>
    <tr>
        <th>이름</th>
        <th>설명</th>
        <th>타입</th>
        <th>기본값</th>
        <th>필수</th>
        <th>예시</th>
    </tr>
</thead>
<tbody>
    <tr>
        <td>create_queue_policy</td>
        <td>SQS 큐 액세스 정책 생성 여부를 결정합니다.</td>
        <td>bool</td>
        <td>true</td>
        <td>no</td>
        <td>false</td>
    </tr>
    <tr>
        <td>sqs_access_services</td>
        <td>AWS 서비스 프린시펄에 대한 SQS 액세스 구성 맵입니다. 키는 서비스 프린시펄(예: <code>sns.amazonaws.com</code>)이며, 값은 메시지 발행 또는 수신이 허용되는 리소스 ARN을 정의합니다.</td>
        <td>map(object)</td>
        <td>null</td>
        <td>no</td>
        <td><pre>{
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
}</pre></td>
    </tr>
    <tr>
        <td>sqs_policy</td>
        <td><code>sqs_access_services</code>에서 생성된 구문과 함께 SQS 큐 정책에 병합할 추가 IAM 정책 구문 목록입니다. 구문에는 고유한 <code>sid</code>가 있어야 합니다.</td>
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
        <th>이름</th>
        <th>설명</th>
        <th>타입</th>
        <th>기본값</th>
        <th>필수</th>
        <th>예시</th>
    </tr>
</thead>
<tbody>
    <tr>
        <td>create_dlq</td>
        <td>메인 SQS 큐에 대한 Dead Letter Queue(DLQ) 생성 여부를 결정합니다. 활성화하면 <code>maxReceiveCount</code> 임계값을 초과한 처리 실패 메시지가 자동으로 DLQ로 이동합니다.</td>
        <td>bool</td>
        <td>false</td>
        <td>no</td>
        <td>true</td>
    </tr>
    <tr>
        <td>dlq_name</td>
        <td>Dead Letter Queue의 이름입니다. 생략하면 <code>sqs_name</code>에 <code>-dlq-sqs</code> 접미사가 붙어 이름이 결정됩니다 (예: <code>my-queue-dlq-sqs</code>). FIFO 큐의 경우 <code>-dlq-sqs.fifo</code>가 붙습니다. <code>dlq_fullname</code>이 설정된 경우 무시됩니다.</td>
        <td>string</td>
        <td>null</td>
        <td>no</td>
        <td>"my-queue-dlq"</td>
    </tr>
    <tr>
        <td>dlq_fullname</td>
        <td>Dead Letter Queue의 전체 이름입니다. 설정하면 해당 값을 그대로 사용하며 <code>dlq_name</code>에서 파생된 이름을 덮어씁니다. FIFO 큐의 경우 <code>.fifo</code> 접미사를 직접 포함해야 합니다.</td>
        <td>string</td>
        <td>null</td>
        <td>no</td>
        <td>"my-custom-exact-dlq-name"</td>
    </tr>
    <tr>
        <td>dlq_delay_seconds</td>
        <td>Dead Letter Queue의 모든 메시지 전달이 지연되는 시간(초)입니다. 0에서 900(15분) 사이의 정수입니다. 설정하지 않으면 <code>delay_seconds</code> 값을 상속합니다.</td>
        <td>number</td>
        <td>null</td>
        <td>no</td>
        <td>30</td>
    </tr>
    <tr>
        <td>dlq_message_retention_seconds</td>
        <td>Amazon SQS가 Dead Letter Queue에서 메시지를 보관하는 시간(초)입니다. 60(1분)에서 1209600(14일) 사이의 정수입니다. 기본값은 조사 및 재처리 시간을 충분히 확보하기 위해 14일입니다.</td>
        <td>number</td>
        <td>1209600</td>
        <td>no</td>
        <td>604800</td>
    </tr>
    <tr>
        <td>dlq_receive_wait_time_seconds</td>
        <td>Dead Letter Queue에서 ReceiveMessage 호출이 메시지 도착을 기다리는 시간(초)입니다. 0에서 20(초) 사이의 정수입니다. 설정하지 않으면 <code>receive_wait_time_seconds</code> 값을 상속합니다.</td>
        <td>number</td>
        <td>null</td>
        <td>no</td>
        <td>20</td>
    </tr>
    <tr>
        <td>dlq_visibility_timeout_seconds</td>
        <td>Dead Letter Queue의 가시성 타임아웃(초)입니다. 0에서 43200(12시간) 사이의 정수입니다. 설정하지 않으면 <code>visibility_timeout_seconds</code> 값을 상속합니다.</td>
        <td>number</td>
        <td>null</td>
        <td>no</td>
        <td>60</td>
    </tr>
    <tr>
        <td>dlq_kms_data_key_reuse_period_seconds</td>
        <td>Amazon SQS가 AWS KMS를 다시 호출하기 전에 데이터 키를 재사용하여 Dead Letter Queue의 메시지를 암호화/복호화할 수 있는 시간(초)입니다. 60(1분)에서 86400(24시간) 사이의 정수입니다. 설정하지 않으면 <code>kms_data_key_reuse_period_seconds</code> 값을 상속합니다.</td>
        <td>number</td>
        <td>null</td>
        <td>no</td>
        <td>3600</td>
    </tr>
    <tr>
        <td>dlq_content_based_deduplication</td>
        <td>FIFO Dead Letter Queue에 대한 콘텐츠 기반 중복 제거를 활성화합니다. <code>fifo_queue</code>가 <code>true</code>인 경우에만 적용됩니다. 설정하지 않으면 <code>content_based_deduplication</code> 값을 상속합니다.</td>
        <td>bool</td>
        <td>null</td>
        <td>no</td>
        <td>true</td>
    </tr>
    <tr>
        <td>dlq_deduplication_scope</td>
        <td>Dead Letter Queue에서 메시지 중복 제거가 메시지 그룹 수준 또는 큐 수준에서 발생하는지 지정합니다. 유효한 값은 <code>messageGroup</code>과 <code>queue</code>입니다. AWS 기본값은 <code>queue</code>입니다. <code>fifo_queue</code>가 <code>true</code>인 경우에만 적용됩니다.</td>
        <td>string</td>
        <td>null</td>
        <td>no</td>
        <td>"messageGroup"</td>
    </tr>
    <tr>
        <td>create_dlq_redrive_allow_policy</td>
        <td>Dead Letter Queue에 대한 Redrive Allow Policy 생성 여부를 결정합니다. 활성화하면 어떤 소스 큐가 이 큐를 Dead Letter Queue로 사용할 수 있는지 지정합니다.</td>
        <td>bool</td>
        <td>true</td>
        <td>no</td>
        <td>false</td>
    </tr>
    <tr>
        <td>dlq_redrive_allow_policy</td>
        <td>Dead Letter Queue Redrive Allow Policy에 병합할 추가 속성입니다. 기본적으로 <code>redrivePermission</code>은 <code>byQueue</code>로, <code>sourceQueueArns</code>는 메인 큐 ARN으로 설정됩니다. 이 변수를 사용하여 기본값을 덮어쓸 수 있습니다.</td>
        <td>any</td>
        <td>null</td>
        <td>no</td>
        <td><pre>모든 소스 큐 허용:
{
  redrivePermission = "allowAll"
}
특정 소스 큐 ARN으로 제한:
{
  redrivePermission = "byQueue"
  sourceQueueArns   = [
    "arn:aws:sqs:ap-northeast-2:111122223333:source-queue"
  ]
}</pre></td>
    </tr>
    <tr>
        <td>create_dlq_queue_policy</td>
        <td>Dead Letter Queue에 대한 액세스 정책 생성 여부를 결정합니다.</td>
        <td>bool</td>
        <td>false</td>
        <td>no</td>
        <td>true</td>
    </tr>
    <tr>
        <td>dlq_policy</td>
        <td><code>dlq_access_services</code>에서 생성된 구문과 함께 Dead Letter Queue 정책에 병합할 추가 IAM 정책 구문 목록입니다. 구문에는 고유한 <code>sid</code>가 있어야 합니다.</td>
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
        <td>AWS 서비스 프린시펄에 대한 Dead Letter SQS 액세스 구성 맵입니다. 키는 서비스 프린시펄(예: <code>sns.amazonaws.com</code>)이며, 값은 메시지 발행 또는 수신이 허용되는 리소스 ARN을 정의합니다.</td>
        <td>map(object)</td>
        <td>null</td>
        <td>no</td>
        <td><pre>{
  "sns.amazonaws.com" = {
    producer_arns = [
      "arn:aws:sns:ap-northeast-2:111122223333:my-topic"
    ]
  }
}</pre></td>
    </tr>
</tbody>
</table>

### 출력 변수

<table>
<thead>
    <tr>
        <th>이름</th>
        <th>설명</th>
        <th>타입</th>
        <th>예시</th>
    </tr>
</thead>
<tbody>
    <tr>
        <td>queue_arn</td>
        <td>SQS 큐의 ARN입니다.</td>
        <td>string</td>
        <td>"arn:aws:sqs:ap-northeast-2:111122223333:my-queue-sqs"</td>
    </tr>
    <tr>
        <td>queue_url</td>
        <td>생성된 Amazon SQS 큐의 URL입니다.</td>
        <td>string</td>
        <td>"https://sqs.ap-northeast-2.amazonaws.com/111122223333/my-queue-sqs"</td>
    </tr>
    <tr>
        <td>queue_name</td>
        <td>SQS 큐의 이름입니다.</td>
        <td>string</td>
        <td>"my-queue-sqs"</td>
    </tr>
    <tr>
        <td>dead_letter_queue_arn</td>
        <td>SQS Dead Letter Queue의 ARN입니다.</td>
        <td>string</td>
        <td>"arn:aws:sqs:ap-northeast-2:111122223333:my-queue-dlq-sqs"</td>
    </tr>
    <tr>
        <td>dead_letter_queue_url</td>
        <td>생성된 Amazon SQS Dead Letter Queue의 URL입니다.</td>
        <td>string</td>
        <td>"https://sqs.ap-northeast-2.amazonaws.com/111122223333/my-queue-dlq-sqs"</td>
    </tr>
    <tr>
        <td>dead_letter_queue_name</td>
        <td>SQS Dead Letter Queue의 이름입니다.</td>
        <td>string</td>
        <td>"my-queue-dlq-sqs"</td>
    </tr>
</tbody>
</table>

# 부록

## AWS SQS 개요

Amazon SQS(Simple Queue Service)는 마이크로서비스, 분산 시스템, 서버리스 애플리케이션의 디커플링 및 스케일링을 지원하는 완전 관리형 메시지 대기열 서비스입니다. 프로듀서와 컨슈머 사이에서 안정적인 메시지 버퍼 역할을 하며, Standard 및 FIFO 큐를 지원합니다.
<br>
자세한 내용은 문서를 참고하세요 : [Amazon Simple Queue Service](https://docs.aws.amazon.com/ko_kr/AWSSimpleQueueService/latest/SQSDeveloperGuide/welcome.html)

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

# 라이선스

- Apache-2.0 라이선스는 [LICENSE](https://github.com/oniops/tfmodule-aws-sqs/blob/main/LICENSE)를 참고하세요.
