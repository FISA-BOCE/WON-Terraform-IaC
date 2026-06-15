# ─────────────────────────────────────────
# Azure Container Registry
# - 이름: 영숫자만 허용, 전역 고유 필요
# - SKU Basic: 실습/개발 환경 (가장 저렴)
# - admin_enabled false: Managed Identity로 인증
# ─────────────────────────────────────────
resource "azurerm_container_registry" "main" {
  name                = "${var.prefix}${var.unique_suffix}acr"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "Basic"
  admin_enabled       = false
  tags                = var.tags
}

# ─────────────────────────────────────────
# AcrPull 권한 부여
# Container Apps의 Managed Identity가
# ACR에서 이미지를 pull할 수 있도록 허용
# ─────────────────────────────────────────
resource "azurerm_role_assignment" "acr_pull" {
  scope                = azurerm_container_registry.main.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.main.principal_id
}
