variable "unique_suffix" {
  description = "전역 고유 리소스 이름 충돌 방지용 suffix"
  type        = string
  default     = "01"
}

variable "prefix" {
  description = "모든 리소스 이름에 붙는 프로젝트 prefix"
  type        = string
  default     = "chatbot"
}

variable "location" {
  description = "Azure 리전"
  type        = string
  default     = "koreacentral"
}

variable "tags" {
  description = "공통 태그"
  type        = map(string)
  default = {
    project     = "chatbot"
    environment = "dev"
    team        = "fintech"
  }
}

# ─────────────────────────────────────────
# Azure 네트워크
# AWS IP 대역 패턴:
#   Card VPC       10.11.0.0/16
#   Securities VPC 10.21.0.0/16
#   Common VPC     10.31.0.0/16
#   Azure VNet     10.41.0.0/16
# ─────────────────────────────────────────
variable "vnet_cidr" {
  type    = string
  default = "10.41.0.0/16"
}

variable "gateway_subnet_cidr" {
  description = "GatewaySubnet - Azure 규칙상 이름 변경 불가"
  type        = string
  default     = "10.41.11.0/24"
}

variable "container_apps_subnet_cidr" {
  description = "Container Apps Subnet - /23은 짝수 옥텟 시작 필수"
  type        = string
  default     = "10.41.20.0/23"
}

variable "pe_subnet_cidr" {
  description = "Private Endpoint Subnet"
  type        = string
  default     = "10.41.31.0/24"
}

# ─────────────────────────────────────────
# AWS VPN 연동
# ─────────────────────────────────────────
variable "aws_vpn_public_ip" {
  description = "AWS Common VPC VGW Public IP (설계 완료 후 입력)"
  type        = string
}

variable "aws_address_spaces" {
  description = "PrivateLink 구조상 공통VPC만 연결하면 됨"
  type        = list(string)
  default     = [
    "10.31.0.0/16",
  ]
}

variable "vpn_shared_key" {
  description = "VPN 터널 공유 키 - AWS VGW 설정과 반드시 동일"
  type        = string
  sensitive   = true
}

# ─────────────────────────────────────────
# Container Apps
# ─────────────────────────────────────────
variable "container_image" {
  type    = string
  default = "chatbot01acr.azurecr.io/won-ai-server:latest"
}

variable "container_cpu" {
  type    = number
  default = 0.5
}

variable "container_memory" {
  type    = string
  default = "1Gi"
}

# ─────────────────────────────────────────
# Azure OpenAI
# ─────────────────────────────────────────
variable "openai_sku" {
  type    = string
  default = "S0"
}

variable "openai_model_name" {
  type    = string
  default = "gpt-4o"
}

variable "openai_model_version" {
  type    = string
  default = "2024-11-20"
}
