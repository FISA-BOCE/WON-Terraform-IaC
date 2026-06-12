
# WON해요 Data Layer IaC 구성 가이드

> 참고: Redis Sentinel HA Terraform 코드는 현재 `99-app-infra`가 아니라 `03-compute/05-redis`에서 관리한다.

## 1. 문서 목적

본 문서는 WON해요 프로젝트의 AWS Data Layer 구성을 Terraform IaC로 관리하기 위한 가이드이다.

이번 구성의 목표는 다음과 같다.

- 카드망과 증권망에 각각 RDS MySQL 구성
- 카드망과 증권망에 각각 EC2 기반 Self-managed Redis 구성
- 카드망 Redis EC2 3대 생성
- 증권망 Redis EC2 3대 생성
- RDS와 Redis 접근 제어용 Security Group을 Terraform에서 신규 생성
- Redis EC2를 Private Data Subnet에 배치
- Redis EC2에 Public IP를 할당하지 않고 고정 Private IP 사용
- EC2 부팅 시 `user_data`로 Redis 설치 및 실행
- Terraform 실행 및 AWS 리소스 생성 확인 절차 정리

> 현재 범위는 카드망과 증권망 각각의 Redis EC2 3대를 유지하면서
> Redis Server + Redis Sentinel을 함께 구성하는 Sentinel 기반 HA까지 포함한다.

---

## 2. 최종 인프라 구성 방향

### 2.1 결정 사항

이번 프로젝트에서는 RDS는 AWS MySQL Multi-AZ DB Instance로 생성한다.

Redis는 ElastiCache가 아닌 EC2 기반 Self-managed Redis로 구성한다.

Redis EC2는 카드망과 증권망에 각각 3대씩 생성한다.


```text
card-vpc
├─ card-data-layer-private-subnet-01
│  ├─ card-redis-01 / 10.11.31.101
│  └─ card-redis-02 / 10.11.31.102
└─ card-data-layer-private-subnet-02
   └─ card-redis-03 / 10.11.32.103


securities-vpc
├─ securities-data-layer-private-subnet-01
│  ├─ securities-redis-01 / 10.21.31.101
│  └─ securities-redis-02 / 10.21.31.102
└─ securities-data-layer-private-subnet-02
   └─ securities-redis-03 / 10.21.32.103
```


### 2.2 Redis 구성 기준

| 구분             | 카드망 Redis           | 증권망 Redis                |
| -------------- | ----------------------- | ------------------------- |
| VPC            | `card-vpc`              | `securities-vpc`          |
| Redis 노드 수     | 3대                   | 3대                        |
| OS             | Ubuntu 24.04 LTS        | Ubuntu 24.04 LTS          |
| AMI            | `ami-0765f9741eedf9c7b` | `ami-0765f9741eedf9c7b`   |
| Instance Type  | `t3.small`              | `t3.small`                |
| Public IP      | 비활성화                 | 비활성화                   |
| Storage        | 20GB gp3                | 20GB gp3                  |
| Security Group | Terraform 신규 생성      | Terraform 신규 생성         |

Redis는 Source of Truth가 아니라 캐시, 임시 상태, 토큰 블랙리스트, 분산 락 등 보조 저장소로 사용한다.

따라서 Redis 장애 시에도 RDS 원장 데이터가 손상되지 않도록 설계하고, Redis 데이터는 재생성 가능한 데이터 중심으로 관리한다.


### 2.3 RDS 구성 기준

| 구분 | 카드망 RDS | 증권망 RDS |
|---|---|---|
| Engine | MySQL | MySQL |
| 배치 위치 | 카드망 Data Layer Private Subnet | 증권망 Data Layer Private Subnet |
| Public Access | 비활성화 | 비활성화 |
| Security Group | Terraform 신규 생성 | Terraform 신규 생성 |
| 접근 포트 | 3306 | 3306 |
| 접근 주체 | 동일 망 App Security Group | 동일 망 App Security Group |

---

## 3. 왜 같은 Private Data Subnet에 배치하는가?

RDS와 Redis는 모두 외부 인터넷에서 직접 접근하지 않는 내부 Data Layer 리소스이다.

다만 역할은 다르다.

| 구분     | RDS                                | Redis                           |
| ------ | ---------------------------------- | ------------------------------- |
| 역할     | 영구 저장소, 트랜잭션 DB                    | 캐시, 분산 락, Rate Limit, 임시 상태 저장  |
| 데이터 성격 | 정합성 중요, 영속성 필요                     | 빠른 조회, 임시 처리 중심                 |
| 주요 데이터 | 포인트 원장, 주문 원장, 체결 원장, Outbox/Inbox | ETF 목록 캐시, 중복 요청 방지 락, 토큰 블랙리스트 |
| 접근 포트  | MySQL 기준 3306                      | Redis 기준 6379                   |

따라서 MVP/포트폴리오 단계에서는 subnet을 과도하게 분리하기보다, 동일한 Data Layer Subnet을 재사용한다.

대신 Security Group을 분리하여 접근 제어를 명확히 한다.

```text
App Security Group
├─ 3306 → RDS Security Group
└─ 6379 → Redis Security Group
```


---

## 4. Terraform 디렉터리 구조

```text
infra/
└─ terraform/
   ├─ providers.tf
   ├─ variables.tf
   ├─ security-groups.tf
   ├─ rds.tf
   ├─ redis.tf
   ├─ modules/
   │  └─ redis-sentinel/
   │     ├─ main.tf
   │     ├─ variables.tf
   │     ├─ outputs.tf
   │     └─ user_data.sh.tpl
   ├─ outputs.tf
   ├─ terraform.tfvars.example
   ├─ terraform.tfvars
```

---

## 5. 파일별 역할

| 파일명 | 역할 |
|---|---|
| `providers.tf` | Terraform과 AWS Provider 설정 |
| `variables.tf` | Terraform 코드에서 사용할 입력 변수 정의 |
| `security-groups.tf` | 카드망/증권망별 App, RDS Security Group 생성 |
| `rds.tf` | RDS DB Subnet Group과 RDS MySQL Instance 생성 |
| `redis.tf` | 카드망/증권망별 Redis Sentinel HA 모듈 호출 |
| `modules/redis-sentinel/*` | Redis EC2, Redis SG, Sentinel user_data, 관련 출력 정의 |
| `outputs.tf` | 생성된 RDS Endpoint, Redis Private IP, Sentinel Endpoint, Instance ID 출력 |
| `terraform.tfvars.example` | 팀원 공유용 변수 예시 파일 |
| `terraform.tfvars` | 실제 변수값 입력 파일, Git 커밋 제외 |

---

## 6. Terraform 파일 흐름

Terraform은 같은 폴더 안의 `.tf` 파일을 모두 읽어서 하나의 실행 계획으로 합친다.

파일 이름 순서대로 실행되는 것이 아니라, Terraform이 리소스 간 참조 관계를 보고 순서를 계산한다.


```text
terraform.tfvars
   ↓
variables.tf
   ↓
providers.tf
   ↓
security-groups.tf
   ↓
rds.tf / redis.tf
   ↓
outputs.tf
```

실제 의미는 다음과 같다.

```text
1. terraform.tfvars에서 실제 값 입력
2. variables.tf에서 입력값의 이름과 타입 정의
3. providers.tf에서 AWS Provider 설정
4. security-groups.tf에서 망별 Security Group 생성
5. rds.tf에서 RDS Subnet Group 및 RDS 생성
6. redis.tf에서 기존 VPC/Subnet 조회 후 망별 redis-sentinel 모듈 호출
7. modules/redis-sentinel/user_data.sh.tpl로 Redis Server와 Redis Sentinel 함께 설치 및 실행
8. outputs.tf에서 생성된 RDS Endpoint와 Redis EC2 접속 정보 출력
```

---

## 7. 사전 설치 도구

Terraform을 실행하려면 아래 도구가 필요하다.

| 도구                | 용도                                |
| ----------------- | --------------------------------- |
| Terraform CLI     | IaC 코드 실행                         |
| AWS CLI           | AWS 계정 인증 및 리소스 확인                |
| kubectl           | EKS Pod에서 연결 테스트                  |
| AWS 계정 Access Key | Terraform이 AWS 리소스를 생성하기 위한 인증 정보 |

---

## 8. Windows PowerShell 기준 설치

### 8.1 Terraform 설치

```powershell
winget install -e --id Hashicorp.Terraform
```

설치 후 PowerShell을 새로 열고 확인한다.

```powershell
terraform -version
```

정상 예시:

```text
Terraform v1.x.x
```

---

### 8.2 AWS CLI 설치

```powershell
winget install -e --id Amazon.AWSCLI
```

설치 후 PowerShell을 새로 열고 확인한다.

```powershell
aws --version
```

---

### 8.3 AWS 인증 정보 설정

```powershell
aws configure
```

입력값 예시:

```text
AWS Access Key ID: 본인 Access Key
AWS Secret Access Key: 본인 Secret Key
Default region name: ap-northeast-2
Default output format: json
```

인증 확인:

```powershell
aws sts get-caller-identity
```

정상이라면 Account, UserId, Arn 정보가 출력된다.

---

## 9. 필요한 변수값

`terraform.tfvars`에 실제 값을 입력한다.

`terraform.tfvars.example`은 팀원 공유용 예시 파일이며, 실제 비밀번호와 실제 AWS 리소스 ID는 로컬 `terraform.tfvars`에만 작성한다.

```hcl
aws_region = "ap-northeast-2"

project = "won"
env     = "dev"

rds_networks = {
  card = {
    vpc_id = "vpc-0d3e23bcbd0f5a040"
    data_subnet_ids = [
      "subnet-0ca680e9f59f0a0be",
      "subnet-0938ef0ef59185a85"
    ]
    db_name     = "wonhaeyocard"
    db_username = "admin"
  }

  securities = {
    vpc_id = "vpc-0a7d58018059ba4b7"
    data_subnet_ids = [
      "subnet-0fb6374baa67d53c2",
      "subnet-06d2b12790b24b9ce"
    ]
    db_name     = "wonhaeyoinvest"
    db_username = "admin"
  }
}

db_passwords = {
  card       = "CHANGE_ME_CARD_DB_PASSWORD"
  securities = "CHANGE_ME_SECURITIES_DB_PASSWORD"
}

db_instance_class     = "db.t4g.micro"
allocated_storage     = 20
max_allocated_storage = 100
rds_multi_az          = true

ec2_ami_id                      = "ami-0765f9741eedf9c7b"
ec2_key_name                    = "boce-keypair"
ec2_associate_public_ip_address = false

redis_instance_type    = "t3.small"
redis_root_volume_size = 20
redis_root_volume_type = "gp3"
redis_port             = 6379
redis_password         = "CHANGE_ME_REDIS_PASSWORD"

redis_networks = {
  card = {
    vpc_name = "card-vpc"
    vpc_cidr = "10.11.0.0/16"
  }

  securities = {
    vpc_name = "securities-vpc"
    vpc_cidr = "10.21.0.0/16"
  }
}

redis_nodes = {
  card_redis_01 = {
    name        = "card-redis-01"
    network_key = "card"
    subnet_name = "card-data-layer-private-subnet-01"
    subnet_cidr = "10.11.31.0/24"
    private_ip  = "10.11.31.101"
  }

  card_redis_02 = {
    name        = "card-redis-02"
    network_key = "card"
    subnet_name = "card-data-layer-private-subnet-01"
    subnet_cidr = "10.11.31.0/24"
    private_ip  = "10.11.31.102"
  }

  card_redis_03 = {
    name        = "card-redis-03"
    network_key = "card"
    subnet_name = "card-data-layer-private-subnet-02"
    subnet_cidr = "10.11.32.0/24"
    private_ip  = "10.11.32.103"
  }

  securities_redis_01 = {
    name        = "securities-redis-01"
    network_key = "securities"
    subnet_name = "securities-data-layer-private-subnet-01"
    subnet_cidr = "10.21.31.0/24"
    private_ip  = "10.21.31.101"
  }

  securities_redis_02 = {
    name        = "securities-redis-02"
    network_key = "securities"
    subnet_name = "securities-data-layer-private-subnet-01"
    subnet_cidr = "10.21.31.0/24"
    private_ip  = "10.21.31.102"
  }

  securities_redis_03 = {
    name        = "securities-redis-03"
    network_key = "securities"
    subnet_name = "securities-data-layer-private-subnet-02"
    subnet_cidr = "10.21.32.0/24"
    private_ip  = "10.21.32.103"
  }
}
```

> `db_passwords`와 `redis_password`에는 실제 운영 비밀번호를 넣지 않는다.  
> 로컬 `terraform.tfvars`에만 실제 값을 작성한다.


---

## 10. 변수 설명

| 변수명 | 설명 | 예시 |
|---|---|---|
| `aws_region` | AWS 리전 | `ap-northeast-2` |
| `project` | 프로젝트 리소스 prefix | `won` |
| `env` | 환경명 | `dev` |
| `rds_networks` | 카드망/증권망 RDS VPC, Subnet, DB 이름 정의 | `card`, `securities` |
| `db_passwords` | 망별 RDS 관리자 비밀번호 | 직접 입력 |
| `db_instance_class` | RDS 인스턴스 클래스 | `db.t4g.micro` |
| `allocated_storage` | RDS 기본 스토리지 용량 | `20` |
| `max_allocated_storage` | RDS 자동 확장 최대 스토리지 용량 | `100` |
| `rds_multi_az` | RDS Multi-AZ 활성화 여부 | `true` |
| `ec2_ami_id` | Redis EC2 AMI ID | `ami-0765f9741eedf9c7b` |
| `ec2_key_name` | Redis EC2 Key Pair 이름 | `boce-keypair` |
| `ec2_associate_public_ip_address` | Redis EC2 Public IP 자동 할당 여부 | `false` |
| `redis_instance_type` | Redis EC2 인스턴스 타입 | `t3.small` |
| `redis_root_volume_size` | Redis EC2 Root Volume 크기 | `20` |
| `redis_root_volume_type` | Redis EC2 Root Volume 타입 | `gp3` |
| `redis_port` | Redis 서비스 포트 | `6379` |
| `redis_password` | Redis 접속 비밀번호 | 직접 입력 |
| `redis_networks` | Redis가 속한 카드망/증권망 VPC 정의 | `card`, `securities` |
| `redis_nodes` | Redis EC2 노드별 이름, Subnet, Private IP 정의 | `card_redis_01` 등 |


---

## 11. Security Group 구성

이번 구성에서는 RDS와 Redis 접근 제어용 Security Group을 Terraform에서 신규 생성한다.


### 11.1 생성되는 Security Group

| Security Group | 용도 |
|---|---|
| `${project}-${env}-card-app-sg` | 카드망 App/WAS 접근 주체 |
| `${project}-${env}-card-rds-mysql-sg` | 카드망 RDS MySQL 접근 제어 |
| `${project}-${env}-card-redis-sg` | 카드망 Redis 접근 제어 |
| `${project}-${env}-securities-app-sg` | 증권망 App/WAS 접근 주체 |
| `${project}-${env}-securities-rds-mysql-sg` | 증권망 RDS MySQL 접근 제어 |
| `${project}-${env}-securities-redis-sg` | 증권망 Redis 접근 제어 |

예시 리소스명은 다음과 같다.

```text
won-dev-card-app-sg
won-dev-card-rds-mysql-sg
won-dev-card-redis-sg
won-dev-securities-app-sg
won-dev-securities-rds-mysql-sg
won-dev-securities-redis-sg
```

### 11.2 Inbound 규칙

| 대상 SG | 포트 | Source |
|---|---:|---|
| 카드망 RDS SG | 3306 | 카드망 App SG |
| 카드망 Redis SG | 6379 | 카드망 App SG |
| 증권망 RDS SG | 3306 | 증권망 App SG |
| 증권망 Redis SG | 6379 | 증권망 App SG |

Redis EC2에는 Redis SG가 직접 연결된다.

```text
card-redis-01/02/03       → won-dev-card-redis-sg
securities-redis-01/02/03 → won-dev-securities-redis-sg
```

App SG는 Redis EC2에 직접 붙는 것이 아니라, Redis SG의 inbound source로 사용된다.

```text
card-app-sg       → card-redis-sg:6379
securities-app-sg → securities-redis-sg:6379
```

### 11.3 Redis Sentinel HA 구성 시 추가 검토 사항

현재 Security Group은 Redis 6379와 Sentinel 26379을 함께 허용하도록 구성한다.

Redis 노드 간 복제와 Sentinel 합의가 필요하므로 Redis 노드 간 통신 규칙이 포함되어야 한다.

| 구성 | 추가 검토 포트 |
|---|---:|
| Redis 노드 간 통신 | 6379 |
| Redis Sentinel | 26379 |

현재 Terraform 범위에는 Redis Sentinel HA 구성과 해당 포트 규칙이 포함된다.

---

## 12. 보안 주의사항

`terraform.tfvars`에는 RDS 비밀번호, Redis 비밀번호 등 민감정보가 들어갈 수 있다.

따라서 GitHub에 올리지 않는다.

`.gitignore`에 아래 내용을 추가한다.

```gitignore
# Terraform local directory
.terraform/

# Terraform state files
*.tfstate
*.tfstate.*
.terraform.tfstate.lock.info

# Terraform variable files with secrets
terraform.tfvars
*.auto.tfvars

# Terraform plan/output files
tfplan
*.tfplan
plan.txt

# Local override files
override.tf
override.tf.json
*_override.tf
*_override.tf.json

# JetBrains IDE
.idea/
```

단, `.terraform.lock.hcl`은 팀원들이 동일한 Provider 버전을 사용하도록 커밋할 수 있다.

커밋하면 안 되는 파일은 다음과 같다.

```text
.terraform/
.terraform.tfstate.lock.info
terraform.tfstate
terraform.tfstate.backup
terraform.tfvars
tfplan
plan.txt
```


---

## 13. Terraform 실행 순서

Terraform 폴더로 이동한다.

```powershell
cd C:\infra\terraform
```

기존 plan 파일이 있다면 삭제한다.

```powershell
Remove-Item tfplan -Force -ErrorAction SilentlyContinue
Remove-Item plan.txt -Force -ErrorAction SilentlyContinue
```

초기화한다.

```powershell
terraform init
```

코드 포맷을 정리한다.

```powershell
terraform fmt
```

문법을 검증한다.

```powershell
terraform validate
```

실행 계획을 저장한다.

```powershell
terraform plan -out=tfplan
```

실행 계획을 파일로 확인한다.

```powershell
terraform show -no-color tfplan > plan.txt
notepad plan.txt
```

실제 AWS에 리소스를 생성한다.

```powershell
terraform apply tfplan
```


---

## 14. 생성되는 주요 리소스

Terraform apply 후 생성되는 리소스는 다음과 같다.

| 리소스 | 설명 |
|---|---|
| App Security Group | RDS/Redis 접근 주체로 사용할 망별 App SG |
| RDS Security Group | 동일 망 App SG에서 오는 3306 포트만 허용 |
| Redis Security Group | 동일 망 App SG에서 오는 6379 포트만 허용 |
| RDS DB Subnet Group | RDS가 배치될 Private Data Subnet 묶음 |
| RDS MySQL Instance | 카드망/증권망 RDS MySQL |
| Redis EC2 Instances | 카드망 Redis 3대, 증권망 Redis 3대 |
| Redis EC2 Root Volumes | 각 Redis EC2별 20GB gp3 Root Volume |
| Redis user_data | EC2 부팅 시 Redis 설치 및 실행 스크립트 |
| Outputs | RDS Endpoint, Redis Private IP, Redis Instance ID 등 출력 |

Redis는 ElastiCache Endpoint가 아니라 EC2 Private IP 기준으로 연결한다.

Redis용 Security Group은 Terraform에서 새로 생성한다.


- 카드망 Redis: `boce-card-wg-sg`
- 증권망 Redis: `boce-securities-test-sg`


---

## 15. Terraform 출력값 확인

전체 output을 확인한다.

```powershell
terraform output
```

개별 확인 예시는 다음과 같다.

```powershell
terraform output rds_endpoints
terraform output rds_addresses
terraform output rds_security_group_ids
terraform output app_security_group_ids
terraform output redis_private_ips
terraform output redis_private_dns
terraform output redis_instance_ids
terraform output redis_security_group_ids
terraform output redis_nodes
```

> 실제 output 이름은 `outputs.tf`에 정의된 이름을 기준으로 확인한다.  
> 코드에서 `rds_endpoint`처럼 단수형으로 정의했다면 해당 이름으로 조회한다.

Redis Private IP 예시는 다음과 같다.

```text
card_redis_01       → 10.11.31.101
card_redis_02       → 10.11.31.102
card_redis_03       → 10.11.32.103
securities_redis_01 → 10.21.31.101
securities_redis_02 → 10.21.31.102
securities_redis_03 → 10.21.32.103
```

---
## 16. AWS 콘솔에서 생성 여부 확인

AWS 콘솔 오른쪽 위 Region이 `Asia Pacific (Seoul)` 또는 `ap-northeast-2`인지 확인한다.

### 16.1 RDS 확인

```text
AWS Console
→ RDS
→ Databases
```

확인 대상:

```text
won-dev-card-mysql
won-dev-securities-mysql
```

확인 항목:

```text
Status: Available
Engine: MySQL
Publicly accessible: No
VPC: card-vpc 또는 securities-vpc
```

### 16.2 Redis EC2 확인

```text
AWS Console
→ EC2
→ Instances
```

확인 대상:

```text
card-redis-01
card-redis-02
card-redis-03
securities-redis-01
securities-redis-02
securities-redis-03
```

확인 항목:

```text
Instance state: Running
Instance type: t3.small
Private IPv4 address: 지정한 IP
Public IPv4 address: 없음
Root volume: 20GB gp3
```

### 16.3 Security Group 확인

```text
AWS Console
→ EC2
→ Security Groups
```

확인 대상:

```text
won-dev-card-app-sg
won-dev-card-rds-mysql-sg
won-dev-card-redis-sg
won-dev-securities-app-sg
won-dev-securities-rds-mysql-sg
won-dev-securities-redis-sg
```

확인 항목:

```text
RDS SG Inbound: 3306 from App SG
Redis SG Inbound: 6379 from App SG
```

---

## 17. AWS CLI로 리소스 생성 확인

### 17.1 RDS 상태 확인

카드망 RDS:

```powershell
aws rds describe-db-instances `
  --db-instance-identifier won-dev-card-mysql `
  --query "DBInstances[0].{Status:DBInstanceStatus,MultiAZ:MultiAZ,Public:PubliclyAccessible,Endpoint:Endpoint.Address}" `
  --output table
```

증권망 RDS:

```powershell
aws rds describe-db-instances `
  --db-instance-identifier won-dev-securities-mysql `
  --query "DBInstances[0].{Status:DBInstanceStatus,MultiAZ:MultiAZ,Public:PubliclyAccessible,Endpoint:Endpoint.Address}" `
  --output table
```

기대 결과:

```text
Status = available
Public = false
Endpoint 확인 가능
```

### 17.2 Redis EC2 상태 확인

```powershell
aws ec2 describe-instances `
  --filters "Name=tag:Name,Values=card-redis-01,card-redis-02,card-redis-03,securities-redis-01,securities-redis-02,securities-redis-03" "Name=instance-state-name,Values=running" `
  --query "Reservations[].Instances[].{Name:Tags[?Key=='Name']|[0].Value,InstanceId:InstanceId,Type:InstanceType,PrivateIp:PrivateIpAddress,PublicIp:PublicIpAddress,State:State.Name}" `
  --output table
```

기대 결과:

```text
State = running
Type = t3.small
PublicIp = null
PrivateIp = 지정한 고정 Private IP
```

---

## 18. 연결 테스트

RDS와 Redis는 Private Subnet에 배치되며 Public IP가 없다.

따라서 로컬 PC에서 직접 접속하는 방식이 아니라, 같은 VPC 내부의 EKS Pod, WAS, Bastion, WireGuard 경로 또는 테스트 EC2에서 연결을 확인한다.

### 18.1 Redis 설치 상태 확인

Redis EC2에 접속 가능한 내부 경로가 있다면 아래 명령어로 확인한다.

```bash
systemctl status redis-server
```

Redis 응답 확인:

```bash
redis-cli -p 6379 -a "<REDIS_PASSWORD>" ping
```

기대 결과:

```text
PONG
```

주의 사항:

```text
Redis EC2는 user_data에서 apt-get으로 Redis를 설치한다.
Private Subnet에 NAT Gateway 또는 외부 패키지 저장소 접근 경로가 없으면 Redis 설치가 실패할 수 있다.
이 경우 EC2는 생성되지만 redis-server가 실행되지 않을 수 있으므로 user_data 로그를 확인해야 한다.
```

user_data 로그 확인:

```bash
sudo tail -n 100 /var/log/cloud-init-output.log
```

### 18.2 EKS Pod에서 RDS 연결 테스트

임시 MySQL client Pod 생성:

```powershell
kubectl create namespace wonhaeyo
```

```powershell
kubectl run mysql-client `
  -n wonhaeyo `
  --image=mysql:8.0 `
  --restart=Never `
  -- sleep 3600
```

Pod 접속:

```powershell
kubectl exec -it mysql-client -n wonhaeyo -- bash
```

Pod 내부에서 MySQL 접속:

```bash
mysql -h <RDS_ENDPOINT> -P 3306 -u <DB_USERNAME> -p
```

접속 후 테스트:

```sql
SELECT 1;
SHOW DATABASES;
```

기대 결과:

```text
SELECT 1 성공
DB 목록 확인
```

### 18.3 EKS Pod에서 Redis 연결 테스트

임시 Redis client Pod 생성:

```powershell
kubectl run redis-client `
  -n wonhaeyo `
  --image=redis:7 `
  --restart=Never `
  -- sleep 3600
```

Pod 접속:

```powershell
kubectl exec -it redis-client -n wonhaeyo -- sh
```

Pod 내부에서 Redis 접속:

```bash
redis-cli -h <REDIS_EC2_PRIVATE_IP> -p 6379 -a "<REDIS_PASSWORD>" ping
```

카드망 Redis 예시:

```bash
redis-cli -h 10.11.31.101 -p 6379 -a "<REDIS_PASSWORD>" ping
```

증권망 Redis 예시:

```bash
redis-cli -h 10.21.31.101 -p 6379 -a "<REDIS_PASSWORD>" ping
```

기대 결과:

```text
PONG
```

쓰기/읽기 테스트:

```bash
redis-cli -h <REDIS_EC2_PRIVATE_IP> -p 6379 -a "<REDIS_PASSWORD>" set test:wonhaeyo ok
redis-cli -h <REDIS_EC2_PRIVATE_IP> -p 6379 -a "<REDIS_PASSWORD>" get test:wonhaeyo
```

기대 결과:

```text
ok
```

### 18.4 Security Group 차단 테스트

App Security Group이 아닌 다른 Security Group을 가진 EC2 또는 Pod에서 RDS/Redis 접속을 시도한다.

기대 결과:

```text
RDS 3306 접속 실패
Redis 6379 접속 실패
```

이 테스트가 성공하면 다음을 의미한다.

```text
RDS는 동일 망 App Security Group에서만 3306 접근이 허용된다.
Redis는 동일 망 App Security Group에서만 6379 접근이 허용된다.
```

---

## 19. Kubernetes Secret 주입 예시

Terraform output으로 나온 RDS Endpoint와 Redis Private IP를 사용해 Kubernetes Secret을 만든다.

카드망 WAS가 카드망 RDS와 카드망 Redis를 사용하는 경우 예시는 다음과 같다.

```powershell
kubectl -n wonhaeyo create secret generic wonhaeyo-data-secret `
  --from-literal=DB_HOST="<CARD_RDS_ENDPOINT>" `
  --from-literal=DB_PORT="3306" `
  --from-literal=DB_NAME="wonhaeyocard" `
  --from-literal=DB_USERNAME="admin" `
  --from-literal=DB_PASSWORD="<RDS_PASSWORD>" `
  --from-literal=REDIS_HOST="10.11.31.101" `
  --from-literal=REDIS_PORT="6379" `
  --from-literal=REDIS_PASSWORD="<REDIS_PASSWORD>"
```

증권망 WAS가 증권망 RDS와 증권망 Redis를 사용하는 경우 예시는 다음과 같다.

```powershell
kubectl -n wonhaeyo create secret generic wonhaeyo-invest-data-secret `
  --from-literal=DB_HOST="<SECURITIES_RDS_ENDPOINT>" `
  --from-literal=DB_PORT="3306" `
  --from-literal=DB_NAME="wonhaeyoinvest" `
  --from-literal=DB_USERNAME="admin" `
  --from-literal=DB_PASSWORD="<RDS_PASSWORD>" `
  --from-literal=REDIS_HOST="10.21.31.101" `
  --from-literal=REDIS_PORT="6379" `
  --from-literal=REDIS_PASSWORD="<REDIS_PASSWORD>"
```

Spring Boot에서는 해당 값을 환경변수로 읽어 DB와 Redis에 연결한다.

---

## 20. Spring Boot 설정 예시

```yaml
spring:
  datasource:
    url: jdbc:mysql://${DB_HOST}:${DB_PORT}/${DB_NAME}?serverTimezone=Asia/Seoul&characterEncoding=UTF-8
    username: ${DB_USERNAME}
    password: ${DB_PASSWORD}
    hikari:
      maximum-pool-size: 5
      minimum-idle: 1
      connection-timeout: 3000
      validation-timeout: 2000

  data:
    redis:
      host: ${REDIS_HOST}
      port: ${REDIS_PORT}
      password: ${REDIS_PASSWORD}
      ssl:
        enabled: false
```

EC2에 직접 구성한 Redis는 기본적으로 TLS를 사용하지 않는다.

따라서 Spring Boot Redis 설정에서는 `ssl.enabled=false`를 사용한다.

EKS Pod가 오토스케일링되면 DB connection도 함께 늘어날 수 있으므로, HikariCP pool size를 과도하게 크게 설정하지 않는다.

---

## 21. 장애 테스트

### 21.1 RDS Failover 테스트

Dev 환경에서만 수행한다.

```powershell
aws rds reboot-db-instance `
  --db-instance-identifier won-dev-card-mysql `
  --force-failover
```

증권망 RDS도 동일하게 테스트할 수 있다.

```powershell
aws rds reboot-db-instance `
  --db-instance-identifier won-dev-securities-mysql `
  --force-failover
```

확인 항목:

```text
RDS Endpoint는 그대로 유지
일시적 DB 연결 오류 발생 가능
WAS가 connection을 재생성하여 복구되는지 확인
API가 일정 시간 후 정상화되는지 확인
Outbox/Inbox 중복 처리 발생 여부 확인
```

### 21.2 Redis EC2 장애 테스트

현재 Redis는 ElastiCache가 아니라 EC2 기반 Self-managed Redis로 구성한다.

따라서 `aws elasticache test-failover` 명령어를 사용하지 않는다.

Redis EC2 장애 테스트는 Dev 환경에서만 수행한다.

```powershell
aws ec2 stop-instances --instance-ids <REDIS_INSTANCE_ID>
```

확인 항목:

```text
Redis 연결 실패 시 WAS가 예외를 안전하게 처리하는지 확인
캐시 miss 발생 시 RDS 기준 데이터로 복구 가능한지 확인
분산 락 처리 중 중복 실행이 발생하지 않는지 확인
Redis 재기동 후 애플리케이션이 정상 재연결하는지 확인
```

테스트 후 인스턴스를 다시 시작한다.

```powershell
aws ec2 start-instances --instance-ids <REDIS_INSTANCE_ID>
```

주의 사항:

```text
현재 Terraform 구성은 카드망 Redis EC2 3대와 증권망 Redis EC2 3대, 총 6대에
Redis Server와 Redis Sentinel을 함께 구성하여 Master-Replica 기반 자동 장애 전환을 수행한다.

Redis Cluster 샤딩은 이번 범위가 아니며, 장애 조치는 Sentinel quorum 2 기준으로 처리한다.
```

---

## 22. 테스트 후 임시 리소스 정리

임시 Pod 삭제:

```powershell
kubectl delete pod mysql-client -n wonhaeyo
kubectl delete pod redis-client -n wonhaeyo
```

개발 테스트 리소스를 모두 삭제하려면:

```powershell
terraform destroy
```

단, 운영 환경에서는 `terraform destroy`를 실행하지 않는다.

---

## 23. 자주 발생한 오류와 해결 방법

### 23.1 `terraform` 명령어를 찾을 수 없음

오류:

```text
terraform : 'terraform' 용어가 cmdlet, 함수, 스크립트 파일 또는 실행할 수 있는 프로그램 이름으로 인식되지 않습니다.
```

원인:

```text
Terraform CLI가 설치되지 않았거나 PATH에 등록되지 않음
```

해결:

```powershell
winget install -e --id Hashicorp.Terraform
```

설치 후 PowerShell을 새로 열고 확인한다.

```powershell
terraform -version
```

### 23.2 `No configuration files`

오류:

```text
Error: No configuration files
```

원인:

```text
terraform plan을 실행한 폴더에 .tf 파일이 없음
```

해결:

```text
providers.tf, variables.tf, rds.tf, redis.tf 등 .tf 파일을 C:\infra\terraform 폴더 안에 둔다.
```

확인:

```powershell
dir *.tf
```

### 23.3 `Inconsistent dependency lock file`

오류:

```text
Error: Inconsistent dependency lock file
```

원인:

```text
Provider 초기화가 안 됐거나 lock file이 현재 설정과 맞지 않음
```

해결:

```powershell
terraform init
```

계속 문제가 나면:

```powershell
Remove-Item -Recurse -Force .terraform
Remove-Item -Force .terraform.lock.hcl
terraform init
```

### 23.4 `No valid credential sources found`

오류:

```text
Error: No valid credential sources found
```

원인:

```text
AWS 인증 정보가 설정되지 않음
```

해결:

```powershell
aws configure
aws sts get-caller-identity
terraform plan
```

### 23.5 `MasterUserPassword is not a valid password`

오류:

```text
InvalidParameterValue: The parameter MasterUserPassword is not a valid password because it is shorter than 8 characters.
```

원인:

```text
RDS 관리자 비밀번호가 8자 미만임
```

해결:

```text
terraform.tfvars의 db_passwords.card, db_passwords.securities 값을 8자 이상으로 수정한다.
```

비밀번호를 수정했다면 기존 plan 파일을 삭제하고 다시 plan을 만든다.

```powershell
Remove-Item tfplan -Force -ErrorAction SilentlyContinue
terraform plan -out=tfplan
terraform apply tfplan
```

### 23.6 Redis EC2는 생성됐지만 Redis 접속이 안 됨

원인 가능성:

```text
Private Subnet에서 apt-get이 외부 패키지 저장소에 접근하지 못함
user_data 실행 실패
Redis Security Group에서 6379 접근 미허용
접속 테스트 주체가 App Security Group을 사용하지 않음
```

확인:

```bash
sudo tail -n 100 /var/log/cloud-init-output.log
systemctl status redis-server
```

---

## 24. 최종 요약

이번 Terraform 구성은 다음 원칙을 따른다.

```text
1. RDS는 카드망과 증권망에 각각 MySQL DB Instance로 구성한다.
2. RDS는 Terraform에서 신규 Security Group을 생성해 3306 접근을 제어한다.
3. Redis는 ElastiCache가 아닌 EC2 기반 Self-managed Redis로 구성한다.
4. 카드망 Redis 3대와 증권망 Redis 3대를 생성한다.
5. Redis EC2는 Private Data Subnet에 배치한다.
6. Redis EC2에는 Public IP를 할당하지 않는다.
7. Redis EC2는 고정 Private IP를 사용한다.
8. Redis EC2에는 Terraform에서 신규 생성한 Redis Security Group을 연결한다.
9. Redis는 6379 포트로 접근한다.
10. Redis는 Redis Cluster가 아니라 Sentinel 기반 Master-Replica HA로 구성한다.
11. EKS/WAS는 Redis 단일 IP가 아니라 Sentinel master name과 Sentinel endpoint 목록으로 연결한다.
```

한 줄로 정리하면 다음과 같다.

> RDS는 카드망/증권망별 MySQL DB로 구성하고, Redis는 각 망의 Private Data Subnet에 EC2 기반 Self-managed 구조로 배치한다.
