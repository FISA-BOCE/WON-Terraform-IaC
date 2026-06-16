# ─────────────────────────────────────────
# Managed Identity (사용자 할당)
# Container Apps가 Key Vault에 접근할 때
# 코드에 API Key 없이 이 신원으로 인증
# ─────────────────────────────────────────
resource "azurerm_user_assigned_identity" "main" {
  name                = "${var.prefix}-identity"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags
}

# ─────────────────────────────────────────
# Container Apps Environment
# Container App들이 실행되는 공유 환경
# - VNet 통합 : infrastructure_subnet_id
# - 내부 전용 : internal_load_balancer_enabled = true
#   → 외부 인터넷 노출 없음
#   → VPN 통해 들어오는 트래픽만 수신
# - Log Analytics 연결 : monitoring.tf에서 생성
# ─────────────────────────────────────────
resource "azurerm_container_app_environment" "main" {
  name                = "${var.prefix}-env"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  # Container Apps Subnet에 배치 (10.41.21.0/23)
  infrastructure_subnet_id = azurerm_subnet.container_apps.id

  # 내부 로드밸런서만 사용 (외부 IP 없음)
  # VPN → GatewaySubnet → Container Apps 경로로만 접근 가능
  internal_load_balancer_enabled = true

  # Log Analytics 연결 (monitoring.tf에서 생성)
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  tags = var.tags

  lifecycle {
    ignore_changes = [
      infrastructure_resource_group_name,
      log_analytics_workspace_id
    ]
  }
}

# ─────────────────────────────────────────
# Container App (챗봇 API 서버)
# - revision_mode "Single" : 배포 시 이전 버전 자동 교체
# - min_replicas 0 : 트래픽 없으면 인스턴스 0개 → 비용 절감
# - max_replicas 3 : 최대 3개까지 자동 스케일아웃
# ─────────────────────────────────────────
resource "azurerm_container_app" "chatbot" {
  name                         = "${var.prefix}-app"
  container_app_environment_id = azurerm_container_app_environment.main.id
  resource_group_name          = azurerm_resource_group.main.name
  revision_mode                = "Single"

  # Managed Identity 연결
  # Key Vault 시크릿 조회 시 이 신원으로 인증
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.main.id]
  }

  secret {
    name                = "openai-api-key"
    key_vault_secret_id = azurerm_key_vault_secret.openai_api_key_actual.id
    identity            = azurerm_user_assigned_identity.main.id
  }

  # ACR 인증: Managed Identity로 이미지 pull
  registry {
    server   = azurerm_container_registry.main.login_server
    identity = azurerm_user_assigned_identity.main.id
  }

  template {
    container {
      name   = "chatbot"
      image  = var.container_image  # 이미지 빌드 후 ACR URL로 교체 (outputs의 acr_image_url 참고)
      cpu    = var.container_cpu    # 0.5 vCPU
      memory = var.container_memory # 1Gi

      # ── 환경변수 ──────────────────────
      # 챗봇 코드에서 이 값들을 읽어서 사용
      # 실제 민감한 값(API Key)은 Key Vault에서 가져옴

      env {
        name  = "AZURE_CLIENT_ID"
        value = azurerm_user_assigned_identity.main.client_id
      }

      env {
        name  = "KEY_VAULT_URL"
        value = azurerm_key_vault.main.vault_uri
      }

      env {
        name  = "AZURE_OPENAI_ENDPOINT"
        value = azurerm_cognitive_account.openai.endpoint
      }

      env {
        name  = "AZURE_OPENAI_MODEL"
        value = var.openai_model_name  # gpt-4o
      }

      env {
        name  = "AZURE_OPENAI_API_VERSION"
        value = "2024-02-01"
      }

      env {
        name        = "AZURE_OPENAI_API_KEY"
        secret_name = "openai-api-key"
      }

      # Neo4j Bolt URI
      # PrivateLink 구조: 공통VPC Interface Endpoint IP 사용
      # AWS 설계 완료 후 실제 Interface Endpoint IP로 교체
      env {
        name  = "NEO4J_CARD_URI"
        value = "bolt://10.31.x.x:7687"
        # placeholder - 공통VPC의 카드VPC PrivateLink Interface Endpoint IP
      }

      env {
        name  = "NEO4J_SECURITIES_URI"
        value = "bolt://10.31.x.x:7687"
        # placeholder - 공통VPC의 증권VPC PrivateLink Interface Endpoint IP
      }

      env {
        name  = "MYSQL_CARD_HOST"
        value = "10.31.x.x"  # placeholder - 공통VPC MySQL PrivateLink Interface Endpoint IP
      }

      env {
        name  = "MYSQL_SECURITIES_HOST"
        value = "10.31.x.x"  # placeholder - 공통VPC MySQL PrivateLink Interface Endpoint IP
      }

      env {
        name  = "MYSQL_PORT"
        value = "3306"
      }

      env {
        name  = "SPRING_PROFILES_ACTIVE"
        value = "prod"
      }
    }

    min_replicas = 1
    max_replicas = 3
  }

  ingress {
    # 외부 인터넷 접근 차단
    # AWS → VPN → GatewaySubnet → Container Apps 경로만 허용
    external_enabled = false
    target_port      = 8090  # Spring Boot WON-AI-SERVER 포트

    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  tags = var.tags
}
