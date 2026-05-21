
# WON해요 Data Layer IaC 구성 가이드

## 1. 문서 목적

본 문서는 WON해요 프로젝트의 AWS Data Layer 구성을 Terraform IaC로 관리하기 위한 가이드이다.

이번 구성의 목표는 다음과 같다.

- RDS MySQL Multi-AZ DB Instance 구성
- ElastiCache Redis Replication Group 구성
- RDS와 Redis를 동일한 AZ별 Private Data Subnet에 배치
- 단, RDS와 Redis는 각각 별도의 Subnet Group과 Security Group으로 분리
- EKS WAS Pod에서 RDS와 Redis에 안전하게 접근할 수 있도록 설정
- Terraform 실행 및 연결 테스트 절차 정리

---

## 2. 최종 인프라 구성 방향

### 2.1 결정 사항

이번 프로젝트에서는 RDS와 Redis를 **같은 Private Data Subnet**에 배치한다.

```text
AZ-A
├─ Private App Subnet
│  └─ EKS Worker Node / WAS Pod
└─ Private Data Subnet
   ├─ Redis Node
   └─ RDS Primary or Standby

AZ-C
├─ Private App Subnet
│  └─ EKS Worker Node / WAS Pod
└─ Private Data Subnet
   ├─ Redis Node
   └─ RDS Primary or Standby
````

단, 같은 subnet을 사용하더라도 아래 항목은 분리한다.

```text
1. RDS DB Subnet Group
2. Redis Cache Subnet Group
3. RDS Security Group
4. Redis Security Group
```

---

## 3. 왜 같은 Subnet에 배치하는가?

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
EKS WAS SG
   ├─ 3306 → RDS SG
   └─ 6379 → Redis SG
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
   ├─ outputs.tf
   └─ terraform.tfvars
```

---

## 5. 파일별 역할

| 파일명                  | 역할                                                               |
| -------------------- | ---------------------------------------------------------------- |
| `providers.tf`       | Terraform과 AWS Provider 설정                                       |
| `variables.tf`       | Terraform 코드에서 사용할 입력 변수 정의                                      |
| `security-groups.tf` | RDS, Redis 접근 제어용 Security Group 생성                              |
| `rds.tf`             | RDS DB Subnet Group과 RDS MySQL Multi-AZ Instance 생성              |
| `redis.tf`           | Redis Cache Subnet Group과 ElastiCache Redis Replication Group 생성 |
| `outputs.tf`         | 생성된 RDS/Redis endpoint, Security Group ID 출력                     |
| `terraform.tfvars`   | 실제 변수값 입력 파일                                                     |

---

## 6. Terraform 파일 흐름

Terraform은 같은 폴더 안의 `.tf` 파일을 모두 읽어서 하나의 실행 계획으로 합친다.

파일 이름 순서대로 실행되는 것이 아니라, Terraform이 리소스 간 참조 관계를 보고 순서를 계산한다.

전체 흐름은 아래와 같다.

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
4. security-groups.tf에서 RDS/Redis 보안그룹 생성
5. rds.tf에서 RDS Subnet Group 및 RDS 생성
6. redis.tf에서 Redis Subnet Group 및 Redis 생성
7. outputs.tf에서 생성된 endpoint 출력
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

```hcl
aws_region = "ap-northeast-2"

project = "wonhaeyo"
env     = "dev"

vpc_id = "vpc-xxxxxxxx"

data_subnet_ids = [
  "subnet-aaaaaaaa", # AZ-A Private Data Subnet
  "subnet-cccccccc"  # AZ-C Private Data Subnet
]

eks_app_security_group_id = "sg-eeeeeeee"

db_name            = "wonhaeyo"
db_username        = "admin"
db_password        = "CHANGE_ME_RDS_PASSWORD"
redis_auth_token   = "CHANGE_ME_REDIS_AUTH_TOKEN"

db_instance_class  = "db.t4g.micro"
redis_node_type    = "cache.t4g.micro"
```

---

## 10. 변수 설명

| 변수명                         | 설명                                           | 예시                         |
| --------------------------- | -------------------------------------------- | -------------------------- |
| `aws_region`                | AWS 리전                                       | `ap-northeast-2`           |
| `project`                   | 프로젝트명                                        | `wonhaeyo`                 |
| `env`                       | 환경명                                          | `dev`                      |
| `vpc_id`                    | 기존 VPC ID                                    | `vpc-xxxxxxxx`             |
| `data_subnet_ids`           | RDS와 Redis가 함께 사용할 Private Data Subnet ID 목록 | `subnet-aaa`, `subnet-ccc` |
| `eks_app_security_group_id` | EKS WAS Node 또는 Pod가 사용하는 Security Group ID  | `sg-eeeeeeee`              |
| `db_name`                   | RDS 초기 DB 이름                                 | `wonhaeyo`                 |
| `db_username`               | RDS 관리자 계정                                   | `admin`                    |
| `db_password`               | RDS 관리자 비밀번호                                 | 직접 입력                      |
| `redis_auth_token`          | Redis 접속 인증 토큰                               | 직접 입력                      |
| `db_instance_class`         | RDS 인스턴스 타입                                  | `db.t4g.micro`             |
| `redis_node_type`           | Redis 노드 타입                                  | `cache.t4g.micro`          |

---

## 11. 보안 주의사항

`terraform.tfvars`에는 비밀번호, Redis 인증 토큰 등 민감정보가 들어갈 수 있다.

따라서 GitHub에 올리지 않는다.

`.gitignore`에 아래 내용을 추가한다.

```gitignore
*.tfvars
.terraform/
```

단, `.terraform.lock.hcl`은 팀원들이 동일한 Provider 버전을 사용하도록 커밋해도 된다.

---

## 12. Terraform 실행 순서

Terraform 폴더로 이동한다.

```powershell
cd C:\infra\terraform
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

실행 계획을 확인한다.

```powershell
terraform plan
```

실제 AWS에 리소스를 생성한다.

```powershell
terraform apply
```

또는 plan 파일을 저장해서 적용할 수 있다.

```powershell
terraform plan -out=tfplan
terraform apply tfplan
```

---

## 13. 생성되는 주요 리소스

Terraform apply 후 생성되는 리소스는 다음과 같다.

| 리소스                      | 설명                                |
| ------------------------ | --------------------------------- |
| RDS Security Group       | EKS WAS에서 오는 3306 포트만 허용          |
| Redis Security Group     | EKS WAS에서 오는 6379 포트만 허용          |
| RDS DB Subnet Group      | AZ-A, AZ-C Private Data Subnet 묶음 |
| RDS MySQL Instance       | Multi-AZ DB Instance              |
| Redis Cache Subnet Group | AZ-A, AZ-C Private Data Subnet 묶음 |
| Redis Replication Group  | Multi-AZ, Automatic Failover 활성화  |
| Outputs                  | RDS endpoint, Redis endpoint 등 출력 |

---

## 14. Terraform 출력값 확인

```powershell
terraform output
```

개별 확인:

```powershell
terraform output rds_endpoint
terraform output rds_address
terraform output redis_primary_endpoint
terraform output redis_reader_endpoint
terraform output rds_security_group_id
terraform output redis_security_group_id
```

이 값들은 이후 EKS WAS 환경변수 또는 Kubernetes Secret에 주입한다.

---

## 15. EKS Secret 주입 예시

Terraform output으로 나온 endpoint를 사용해 Kubernetes Secret을 만든다.

```powershell
kubectl -n wonhaeyo create secret generic wonhaeyo-data-secret `
  --from-literal=DB_HOST="RDS_ENDPOINT" `
  --from-literal=DB_PORT="3306" `
  --from-literal=DB_NAME="wonhaeyo" `
  --from-literal=DB_USERNAME="admin" `
  --from-literal=DB_PASSWORD="RDS_PASSWORD" `
  --from-literal=REDIS_HOST="REDIS_ENDPOINT" `
  --from-literal=REDIS_PORT="6379" `
  --from-literal=REDIS_PASSWORD="REDIS_AUTH_TOKEN"
```

Spring Boot에서는 해당 값을 환경변수로 읽어 DB와 Redis에 연결한다.

---

## 16. Spring Boot 설정 예시

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
        enabled: true
```

EKS Pod가 오토스케일링되면 DB connection도 함께 늘어날 수 있으므로, HikariCP pool size를 과도하게 크게 설정하지 않는다.

---

## 17. 테스트 순서

### 17.1 Terraform 코드 테스트

```powershell
terraform init
terraform fmt
terraform validate
terraform plan
```

기대 결과:

```text
Terraform 문법 오류 없음
생성 예정 리소스 확인 가능
```

---

### 17.2 AWS 리소스 생성 확인

```powershell
terraform apply
```

생성 후 RDS 확인:

```powershell
aws rds describe-db-instances `
  --db-instance-identifier wonhaeyo-dev-mysql `
  --query "DBInstances[0].{Status:DBInstanceStatus,MultiAZ:MultiAZ,Public:PubliclyAccessible,Endpoint:Endpoint.Address}"
```

기대 결과:

```text
Status = available
MultiAZ = true
Public = false
```

Redis 확인:

```powershell
aws elasticache describe-replication-groups `
  --replication-group-id wonhaeyo-dev-redis `
  --query "ReplicationGroups[0].{Status:Status,MultiAZ:MultiAZ,AutomaticFailover:AutomaticFailover}"
```

기대 결과:

```text
Status = available
MultiAZ = enabled
AutomaticFailover = enabled
```

---

### 17.3 EKS Pod에서 RDS 연결 테스트

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
wonhaeyo DB 확인
```

---

### 17.4 EKS Pod에서 Redis 연결 테스트

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
redis-cli -h <REDIS_PRIMARY_ENDPOINT> -p 6379 --tls -a "<REDIS_AUTH_TOKEN>" ping
```

기대 결과:

```text
PONG
```

쓰기/읽기 테스트:

```bash
redis-cli -h <REDIS_PRIMARY_ENDPOINT> -p 6379 --tls -a "<REDIS_AUTH_TOKEN>" set test:wonhaeyo ok
redis-cli -h <REDIS_PRIMARY_ENDPOINT> -p 6379 --tls -a "<REDIS_AUTH_TOKEN>" get test:wonhaeyo
```

기대 결과:

```text
ok
```

---

### 17.5 Security Group 차단 테스트

EKS WAS Security Group이 아닌 다른 Security Group을 가진 EC2 또는 Pod에서 RDS/Redis 접속을 시도한다.

기대 결과:

```text
RDS 3306 접속 실패
Redis 6379 접속 실패
```

이 테스트가 성공하면 다음을 의미한다.

```text
같은 VPC 또는 같은 Subnet에 있어도,
허용된 Security Group을 가진 EKS WAS만 RDS/Redis에 접근 가능하다.
```

---

### 17.6 WAS 애플리케이션 연결 테스트

WAS 배포 후 아래 항목을 확인한다.

```text
1. WAS Pod 정상 기동
2. DB connection pool 생성 성공
3. Redis connection 성공
4. /actuator/health 정상
5. 로그인 또는 카드 조회 API 정상
6. Redis 캐시 또는 Rate Limit 기능 정상
```

---

### 17.7 Pod Scale 테스트

WAS replica 수를 늘린다.

```powershell
kubectl scale deployment wonhaeyo-api `
  -n wonhaeyo `
  --replicas=3
```

Pod 확인:

```powershell
kubectl get pod -n wonhaeyo -o wide
```

확인 항목:

```text
Pod 3개 모두 정상 기동
DB connection이 과도하게 증가하지 않음
Redis 연결 정상
```

---

### 17.8 RDS Failover 테스트

Dev 환경에서만 수행한다.

```powershell
aws rds reboot-db-instance `
  --db-instance-identifier wonhaeyo-dev-mysql `
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

---

### 17.9 Redis Failover 테스트

Dev 환경에서만 수행한다.

```powershell
aws elasticache test-failover `
  --replication-group-id wonhaeyo-dev-redis `
  --node-group-id 0001
```

확인 항목:

```text
Redis 연결이 일시적으로 끊겼다가 복구되는지 확인
Spring Redis Client가 재연결하는지 확인
캐시 miss 발생 시 RDS 기준 데이터로 복구 가능한지 확인
분산 락 처리 중 중복 실행이 발생하지 않는지 확인
```

---

## 18. 테스트 후 임시 리소스 정리

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

## 19. 자주 발생한 오류와 해결 방법

### 19.1 `terraform` 명령어를 찾을 수 없음

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

---

### 19.2 `No configuration files`

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

---

### 19.3 `Inconsistent dependency lock file`

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

---

### 19.4 `No valid credential sources found`

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

---

## 20. 최종 요약

이번 Terraform 구성은 다음 원칙을 따른다.

```text
1. RDS와 Redis는 같은 AZ별 Private Data Subnet을 사용한다.
2. RDS와 Redis는 각각 별도의 Subnet Group을 가진다.
3. RDS와 Redis는 각각 별도의 Security Group을 가진다.
4. EKS WAS Security Group에서 오는 트래픽만 허용한다.
5. RDS는 3306 포트만 허용한다.
6. Redis는 6379 포트만 허용한다.
7. EKS WAS는 Terraform output으로 나온 endpoint를 Secret으로 주입받아 연결한다.
```

한 줄로 정리하면 다음과 같다.

> 같은 Data Subnet 재사용, Subnet Group 분리, Security Group 분리, EKS Secret 기반 연결.
