# ─────────────────────────────────────────
# Outputs
# terraform apply 완료 후 출력되는 값들
# 다른 팀(AWS 담당자 등)과 공유하거나
# 이후 설정에 필요한 값들을 모아놓음
# ─────────────────────────────────────────

# ── 기본 정보 ─────────────────────────────
output "resource_group_name" {
  description = "리소스 그룹 이름"
  value       = azurerm_resource_group.main.name
}

output "location" {
  description = "Azure 리전"
  value       = azurerm_resource_group.main.location
}

# ── 네트워크 ──────────────────────────────
output "vnet_id" {
  description = "VNet ID"
  value       = azurerm_virtual_network.main.id
}

output "vnet_address_space" {
  description = "Azure VNet 주소 범위 (AWS 팀에 공유)"
  value       = azurerm_virtual_network.main.address_space
}

output "subnet_gateway" {
  description = "GatewaySubnet CIDR"
  value       = azurerm_subnet.gateway.address_prefixes
}

output "subnet_container_apps" {
  description = "Container Apps Subnet CIDR"
  value       = azurerm_subnet.container_apps.address_prefixes
}

output "subnet_private_endpoint" {
  description = "Private Endpoint Subnet CIDR"
  value       = azurerm_subnet.private_endpoint.address_prefixes
}

# ── VPN Gateway ───────────────────────────
output "vpn_gateway_public_ip" {
  description = <<-EOT
    ★ AWS 담당자에게 전달 필수 ★
    AWS Common VPC VGW 에 이 IP를 Customer Gateway로 등록해야
    Site-to-Site VPN 연결이 수립됨
  EOT
  value       = azurerm_public_ip.vpn_gateway.ip_address
}

output "vpn_gateway_id" {
  description = "VPN Gateway 리소스 ID"
  value       = azurerm_virtual_network_gateway.main.id
}

# ── Container Apps ────────────────────────
output "container_app_environment_id" {
  description = "Container Apps Environment ID"
  value       = azurerm_container_app_environment.main.id
}

output "container_app_fqdn" {
  description = "챗봇 API 내부 FQDN (VPN 통해서만 접근 가능)"
  value       = azurerm_container_app.chatbot.latest_revision_fqdn
}

# ── Managed Identity ──────────────────────
output "managed_identity_client_id" {
  description = "Managed Identity Client ID (container_apps.tf 환경변수 AZURE_CLIENT_ID 값 확인용)"
  value       = azurerm_user_assigned_identity.main.client_id
}

output "managed_identity_principal_id" {
  description = "Managed Identity Principal ID (Key Vault 접근 정책 확인용)"
  value       = azurerm_user_assigned_identity.main.principal_id
}

# ── Key Vault ─────────────────────────────
output "key_vault_uri" {
  description = "Key Vault URI (Python 코드의 KEY_VAULT_URL 환경변수에 사용)"
  value       = azurerm_key_vault.main.vault_uri
}

output "key_vault_id" {
  description = "Key Vault 리소스 ID"
  value       = azurerm_key_vault.main.id
}

# ── OpenAI ────────────────────────────────
output "openai_endpoint" {
  description = "Azure OpenAI 엔드포인트 (Python 코드의 OPENAI_ENDPOINT 환경변수에 사용)"
  value       = azurerm_cognitive_account.openai.endpoint
}

output "openai_id" {
  description = "Azure OpenAI 리소스 ID"
  value       = azurerm_cognitive_account.openai.id
}

# ── ACR ──────────────────────────────
output "acr_login_server" {
  description = "ACR 로그인 서버 주소 (docker push 시 사용)"
  value       = azurerm_container_registry.main.login_server
}

output "acr_image_url" {
  description = "이미지 push/pull URL — docker build 후 이 값으로 container_image 변수 교체"
  value       = "${azurerm_container_registry.main.login_server}/won-ai-server:latest"
}

# ── Monitoring ────────────────────────────
output "log_analytics_workspace_id" {
  description = "Log Analytics Workspace ID"
  value       = azurerm_log_analytics_workspace.main.id
}

output "log_analytics_workspace_key" {
  description = "Log Analytics Workspace Primary Key"
  value       = azurerm_log_analytics_workspace.main.primary_shared_key
  sensitive   = true  # terraform output 시 숨김, terraform output -raw 로 확인
}

# ── 다음 작업 안내 ────────────────────────
output "next_steps" {
  description = "terraform apply 후 해야 할 작업 목록"
  value       = <<-EOT
    ==============================
    다음 작업 목록
    ==============================
    1. VPN 연결 수립
       - vpn_gateway_public_ip 값을 AWS 담당자에게 전달
       - AWS Common VPC에 Customer Gateway 등록
       - Site-to-Site VPN Connection 생성

    2. Neptune 엔드포인트 업데이트
       - AWS Neo4j EC2 생성 후 실제 엔드포인트 확인
       - Key Vault 시크릿 교체:
           neo4j-card-uri
           neo4j-securities-uri
       - container_apps.tf 환경변수도 업데이트

    3. 챗봇 코드 개발 (Python FastAPI)
       - Azure Container Registry 에 이미지 push
       - container_apps.tf 의 container_image 변수 교체 후
         terraform apply 재실행

    4. Azure OpenAI 구독 승인 확인
       - https://aka.ms/oai/access
    ==============================
  EOT
}
