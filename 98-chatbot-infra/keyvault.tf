data "azurerm_client_config" "current" {}

# ─────────────────────────────────────────
# Azure Key Vault
# public_network_access_enabled = true
# Terraform이 로컬 PC에서 시크릿을 생성하려면
# 공개 접근이 허용되어야 함
# (프로덕션에서는 false로 변경)
# ─────────────────────────────────────────
resource "azurerm_key_vault" "main" {
  name                = "${var.prefix}-${var.unique_suffix}-kv"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tenant_id = data.azurerm_client_config.current.tenant_id
  sku_name  = "standard"

  public_network_access_enabled = true  # Terraform 접근을 위해 허용
  soft_delete_retention_days    = 7
  purge_protection_enabled      = false

  tags = var.tags
}

# ─────────────────────────────────────────
# 접근 정책 1 : Managed Identity (Container Apps)
# ─────────────────────────────────────────
resource "azurerm_key_vault_access_policy" "container_apps" {
  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_user_assigned_identity.main.principal_id

  secret_permissions = ["Get", "List"]
}

# ─────────────────────────────────────────
# 접근 정책 2 : Terraform 실행자
# ─────────────────────────────────────────
resource "azurerm_key_vault_access_policy" "deployer" {
  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  secret_permissions = ["Get", "List", "Set", "Delete", "Purge"]
}

# ─────────────────────────────────────────
# Key Vault 시크릿
# ─────────────────────────────────────────
resource "azurerm_key_vault_secret" "neo4j_card_uri" {
  name         = "neo4j-card-uri"
  value        = "bolt://10.31.x.x:7687"
  key_vault_id = azurerm_key_vault.main.id
  depends_on   = [azurerm_key_vault_access_policy.deployer]
}

resource "azurerm_key_vault_secret" "neo4j_securities_uri" {
  name         = "neo4j-securities-uri"
  value        = "bolt://10.31.x.x:7687"
  key_vault_id = azurerm_key_vault.main.id
  depends_on   = [azurerm_key_vault_access_policy.deployer]
}

resource "azurerm_key_vault_secret" "neo4j_card_password" {
  name         = "neo4j-card-password"
  value        = "placeholder-change-after-neo4j-setup"
  key_vault_id = azurerm_key_vault.main.id
  depends_on   = [azurerm_key_vault_access_policy.deployer]
}

resource "azurerm_key_vault_secret" "neo4j_securities_password" {
  name         = "neo4j-securities-password"
  value        = "placeholder-change-after-neo4j-setup"
  key_vault_id = azurerm_key_vault.main.id
  depends_on   = [azurerm_key_vault_access_policy.deployer]
}

resource "azurerm_key_vault_secret" "mysql_card_connection" {
  name         = "mysql-card-connection"
  value        = "placeholder-card-mysql-endpoint"
  key_vault_id = azurerm_key_vault.main.id
  depends_on   = [azurerm_key_vault_access_policy.deployer]
}

resource "azurerm_key_vault_secret" "mysql_securities_connection" {
  name         = "mysql-securities-connection"
  value        = "placeholder-securities-mysql-endpoint"
  key_vault_id = azurerm_key_vault.main.id
  depends_on   = [azurerm_key_vault_access_policy.deployer]
}
