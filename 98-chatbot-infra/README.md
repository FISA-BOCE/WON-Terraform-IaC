# Azure 챗봇 인프라 — Terraform

금융권 모바일 앱(카드사/증권사)의 AI 챗봇 서비스를 위한 Azure 인프라 코드입니다.

---

## 서비스 개요

사용자가 앱 내 채팅창에서 자연어로 질문하면, AWS에 있는 Graph DB(Neptune)와
MySQL에서 데이터를 조회하고 Azure OpenAI가 자연어 답변을 생성합니다.

**답변 가능한 질문 유형**
- 결제내역, 포인트 잔액 등 단순 조회 → MySQL EC2 조회
- 결제→포인트→주식 전환 관계 분석 → Neptune Graph DB 조회

---

## 아키텍처

```
[모바일 앱]
    ↓ HTTPS
[AWS] Route53 → WAF → API Gateway → EKS WAS
    ↓ Site-to-Site VPN (암호화)
[Azure - GatewaySubnet]
    VPN Gateway (VpnGw1AZ)
    ↓ NSG 검증
[Azure - Container Apps Subnet]
    Azure Container Apps (Python FastAPI 챗봇)
    ├── OpenAI 1차 호출: 질문 유형 파악
    │     단순 조회 → Text-to-SQL → MySQL 조회
    │     관계 조회 → Text-to-Cypher → Neptune 조회
    │     ↕ VPN (Azure → AWS)
    │     MySQL EC2 / Neptune Graph DB
    └── OpenAI 2차 호출: 자연어 답변 생성
    ↓
[Azure - Private Endpoint Subnet]
    OpenAI Private Endpoint
    Key Vault Private Endpoint
[Monitoring - VNet 외부 PaaS]
    Log Analytics, Azure Monitor
```

---

## IP 대역 설계

AWS와 동일한 패턴으로 설계하여 관리 용이성 확보

| 구분 | 대역 | 비고 |
|---|---|---|
| AWS 카드VPC | 10.11.0.0/16 | |
| AWS 증권VPC | 10.21.0.0/16 | |
| AWS 공통VPC | 10.31.0.0/16 | VPN 연결 대상 (PrivateLink 허브) |
| **Azure VNet** | **10.41.0.0/16** | AWS 패턴 동일 |

### Azure 서브넷

| 서브넷 | 대역 | 역할 | 크기 선택 이유 |
|---|---|---|---|
| GatewaySubnet | 10.41.11.0/24 | VPN Gateway | .11 = DMZ 패턴 |
| Container Apps | 10.41.20.0/23 | 챗봇 API 서버 | Azure 강제 최솟값 /23 |
| Private Endpoint | 10.41.31.0/24 | OpenAI·Key Vault PE | .31 = 데이터 패턴 |

---

## 파일 구조

```
terraform/
├── providers.tf         # Azure 프로바이더 설정
├── variables.tf         # 변수 정의 (IP 대역, SKU 등)
├── main.tf              # 리소스 그룹
├── networking.tf        # VNet, 서브넷, NSG
├── vpn_gateway.tf       # VPN Gateway, Local GW, Connection
├── container_apps.tf    # Managed Identity, Container Apps
├── keyvault.tf          # Key Vault, 접근 정책, 시크릿
├── private_endpoints.tf # OpenAI·Key Vault Private Endpoint, DNS
├── openai.tf            # Azure OpenAI, 모델 배포
├── acr.tf               # Azure Container Registry
├── monitoring.tf        # Log Analytics, Diagnostic Settings
└── outputs.tf           # 배포 후 출력값
```

---

## 보안 설계

### 네트워크 보안

| 구간 | 보안 수단 |
|---|---|
| 앱 → AWS | AWS WAF + API Gateway 인증 |
| AWS → Azure | Site-to-Site VPN 암호화 터널 |
| VPN GW → Container Apps | NSG (AWS VPN 대역만 인바운드 허용) |
| Container Apps → OpenAI | Private Endpoint (인터넷 미경유) |
| Container Apps → Key Vault | Private Endpoint + Managed Identity |

### NSG 규칙 (Container Apps Subnet)

| 방향 | 포트 | 대상 | 목적 |
|---|---|---|---|
| Inbound | 443 | GatewaySubnet | AWS VPN 트래픽 허용 |
| Inbound | * | AzureLoadBalancer | 헬스체크 허용 |
| Inbound | * | * | **전체 차단** |
| Outbound | 443 | PE Subnet | OpenAI·Key Vault 호출 |
| Outbound | 443 | AzureCloud | Container Apps 관리 플레인 |
| Outbound | 7687 | 10.31.0.0/16 | 카드VPC Neo4j (공통VPC PrivateLink 경유) |
| Outbound | 3306 | 10.31.0.0/16 | 카드VPC MySQL (공통VPC PrivateLink 경유) |
| Outbound | 3306 | 10.31.0.0/16 | 증권VPC MySQL (공통VPC PrivateLink 경유) |
| Outbound | 53 | * | DNS 조회 |

### 시크릿 관리 (Key Vault)

| 시크릿 | 설명 | 관리 파일 |
|---|---|---|
| openai-api-key | Azure OpenAI API Key | openai.tf 자동 저장 |
| neo4j-card-uri | 카드VPC Neo4j 접속 정보 | keyvault.tf (placeholder) |
| neo4j-securities-uri | 증권VPC Neo4j 접속 정보 | keyvault.tf (placeholder) |
| mysql-card-connection | 카드VPC MySQL 접속 정보 | keyvault.tf (placeholder) |
| mysql-securities-connection | 증권VPC MySQL 접속 정보 | keyvault.tf (placeholder) |

---

## 요청 흐름 (Text-to-SQL / Text-to-Cypher)

```
① 사용자: "스타벅스 결제가 ETF로 얼마가 됐어?"

② 앱 → AWS API GW → EKS WAS
   ↓ VPN ①
③ Azure Container Apps 수신

④ OpenAI 1차 호출 (질문 유형 + 쿼리 변환)
   단순 조회 → Text-to-SQL  → MySQL 조회  (VPN ②③)
   관계 조회 → Text-to-Cypher → Neptune 조회 (VPN ②③)

⑤ OpenAI 2차 호출 (자연어 답변 생성)
   고객 데이터 Azure 저장 없음, 생성 후 즉시 소멸

⑥ 답변 → AWS → 앱 화면 (VPN ④)

총 VPN 통과: 4회 / OpenAI 호출: 2회 / 예상 응답시간: 2~4초
```

---

## 배포 방법

### 사전 요구사항

```bash
# Terraform 설치 확인
terraform version  # >= 1.5 필요

# Azure CLI 로그인
az login
az account set --subscription "<구독 ID>"

# Azure OpenAI 사전 승인
# https://aka.ms/oai/access 에서 신청 후 승인 대기
```

### 배포 순서

```bash
# 1. 초기화
terraform init

# 2. 플랜 확인 (실제 배포 전 검토)
terraform plan

# 3. 배포 (VPN Gateway 생성에 25~45분 소요)
terraform apply

# 4. 배포 후 출력값 확인
terraform output
# → vpn_gateway_public_ip 를 AWS 담당자에게 전달
```

### 실습 후 비용 정리

```bash
# 전체 리소스 삭제
terraform destroy

# Container Apps는 min_replicas=0 설정으로
# 트래픽 없을 때 자동으로 비용 발생 안 함
```

---

## 배포 후 해야 할 작업

### 1. VPN 연결 수립
```
terraform output vpn_gateway_public_ip
→ 출력된 IP를 AWS 담당자에게 전달
→ AWS Common VPC에 Customer Gateway 등록
→ Site-to-Site VPN Connection 생성
→ VPN 공유 키: variables.tf의 vpn_shared_key와 동일하게 설정
```

### 2. Key Vault 시크릿 교체

AWS 설계 완료 후 아래 placeholder 값을 실제 값으로 교체

```bash
az keyvault secret set \
  --vault-name "chatbot-kv" \
  --name "neo4j-card-uri" \
  --value "wss://<실제-neptune-endpoint>:8182/gremlin"

az keyvault secret set \
  --vault-name "chatbot-kv" \
  --name "mysql-card-connection" \
  --value "<실제-mysql-ip>:3306"
```

### 3. 챗봇 코드 배포 (Python FastAPI)

```bash
# Docker 이미지 빌드 및 Azure Container Registry push
docker build -t chatbot-app .
az acr login --name <registry-name>
docker push <registry-name>.azurecr.io/chatbot-app:latest

# container_apps.tf의 container_image 변수 교체 후
terraform apply
```

---

## 생성되는 리소스 목록 (총 34개)

| 파일 | 리소스 |
|---|---|
| main.tf | 리소스 그룹 |
| networking.tf | VNet, 서브넷 3개, NSG, NSG 연결, NSG 규칙 2개 |
| vpn_gateway.tf | Public IP, VPN Gateway, Local Network GW, VPN Connection |
| container_apps.tf | Managed Identity, CA Environment, Container App |
| keyvault.tf | Key Vault, 접근정책 2개, 시크릿 4개 |
| openai.tf | Azure OpenAI, 모델 배포, 시크릿 1개 |
| private_endpoints.tf | PE 2개, DNS Zone 2개, DNS VNet Link 2개 |
| monitoring.tf | Log Analytics, Diagnostic Settings 4개 |

---

## 주요 변수

`variables.tf` 에서 수정

| 변수 | 기본값 | 설명 |
|---|---|---|
| prefix | chatbot | 리소스 이름 prefix |
| location | koreacentral | Azure 리전 |
| aws_vpn_public_ip | 1.1.1.1 | AWS VGW Public IP (교체 필요) |
| vpn_shared_key | changeme-... | VPN 공유 키 (교체 필요) |
| container_image | helloworld | 챗봇 이미지 (교체 필요) |
| openai_model_name | gpt-4o | OpenAI 모델명 |
