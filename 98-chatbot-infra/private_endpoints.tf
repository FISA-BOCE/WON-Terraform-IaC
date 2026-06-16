# ─────────────────────────────────────────
# Private Endpoint 구성 흐름
#
# 1. Private Endpoint 생성
#    → PE Subnet 안에 NIC(네트워크 카드) 생성
#    → 사설 IP 자동 할당 (10.41.31.x)
#
# 2. Private DNS Zone 생성
#    → Azure 서비스 FQDN을 사설 IP로 변환하는 규칙
#    → 예) chatbot-openai.openai.azure.com → 10.41.31.4
#
# 3. DNS Zone ↔ VNet 연결
#    → VNet 안에서 이 DNS 규칙이 작동하도록 연결
#
# 4. DNS Zone Group (PE ↔ DNS 연동)
#    → PE 생성 시 DNS 레코드 자동 등록/삭제
# ─────────────────────────────────────────


# ═══════════════════════════════════════
# OpenAI Private Endpoint
# ═══════════════════════════════════════

resource "azurerm_private_endpoint" "openai" {
  name                = "${var.prefix}-openai-pe"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = azurerm_subnet.private_endpoint.id  # 10.41.31.0/24

  private_service_connection {
    name                           = "${var.prefix}-openai-psc"
    private_connection_resource_id = azurerm_cognitive_account.openai.id
    subresource_names              = ["account"]  # OpenAI PE 서브리소스 타입
    is_manual_connection           = false
  }

  # DNS Zone Group: PE 생성/삭제 시 DNS 레코드 자동 관리
  private_dns_zone_group {
    name                 = "openai-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.openai.id]
  }

  tags = var.tags
}

# OpenAI DNS Zone
# Container Apps 에서 chatbot-openai.openai.azure.com 호출 시
# 이 DNS Zone이 사설 IP(10.41.31.x)로 변환
resource "azurerm_private_dns_zone" "openai" {
  name                = "privatelink.openai.azure.com"
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags
}

# OpenAI DNS Zone → VNet 연결
# 이 연결 없으면 VNet 안에서 DNS 조회 안됨
resource "azurerm_private_dns_zone_virtual_network_link" "openai" {
  name                  = "${var.prefix}-openai-dns-link"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.openai.name
  virtual_network_id    = azurerm_virtual_network.main.id
  registration_enabled  = false  # 수동 DNS 레코드 등록 방지
  tags                  = var.tags
}


# ═══════════════════════════════════════
# Key Vault Private Endpoint
# ═══════════════════════════════════════

resource "azurerm_private_endpoint" "keyvault" {
  name                = "${var.prefix}-kv-pe"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = azurerm_subnet.private_endpoint.id  # 10.41.31.0/24

  private_service_connection {
    name                           = "${var.prefix}-kv-psc"
    private_connection_resource_id = azurerm_key_vault.main.id
    subresource_names              = ["vault"]  # Key Vault PE 서브리소스 타입
    is_manual_connection           = false
  }

  # DNS Zone Group: PE 생성/삭제 시 DNS 레코드 자동 관리
  private_dns_zone_group {
    name                 = "keyvault-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.keyvault.id]
  }

  tags = var.tags
}

# Key Vault DNS Zone
# Managed Identity가 chatbot-kv.vault.azure.net 호출 시
# 이 DNS Zone이 사설 IP(10.41.31.x)로 변환
resource "azurerm_private_dns_zone" "keyvault" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags
}

# Key Vault DNS Zone → VNet 연결
resource "azurerm_private_dns_zone_virtual_network_link" "keyvault" {
  name                  = "${var.prefix}-kv-dns-link"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.keyvault.name
  virtual_network_id    = azurerm_virtual_network.main.id
  registration_enabled  = false
  tags                  = var.tags
}
