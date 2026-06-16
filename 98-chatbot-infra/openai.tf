resource "azurerm_cognitive_account" "openai" {
  name                = "${var.prefix}-${var.unique_suffix}-openai"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  kind                = "OpenAI"
  sku_name            = var.openai_sku

  public_network_access_enabled = false
  custom_subdomain_name         = "${var.prefix}-${var.unique_suffix}-openai"

  identity {
    type = "SystemAssigned"
  }

  network_acls {
    default_action = "Deny"
    ip_rules       = []
  }

  tags = var.tags
}

# ─────────────────────────────────────────
# OpenAI 모델 배포
# GlobalStandard: Korea Central에서 Standard 미지원으로 변경
# ─────────────────────────────────────────
resource "azurerm_cognitive_deployment" "gpt4o" {
  name                 = var.openai_model_name
  cognitive_account_id = azurerm_cognitive_account.openai.id

  model {
    format  = "OpenAI"
    name    = var.openai_model_name
    version = var.openai_model_version
  }

  scale {
    type     = "GlobalStandard"  # Korea Central은 Standard 미지원
    capacity = 10
  }
}

resource "azurerm_key_vault_secret" "openai_api_key_actual" {
  name         = "openai-api-key"
  value        = azurerm_cognitive_account.openai.primary_access_key
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [
    azurerm_key_vault_access_policy.deployer,
    azurerm_private_endpoint.keyvault
  ]
}
