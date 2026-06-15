# ─────────────────────────────────────────
# Log Analytics Workspace
# 모든 리소스의 로그/메트릭이 모이는 중앙 저장소
# Container Apps Environment 가 이 ID를 참조함
#
# retention_in_days = 30
# 실습 수준으로 최소값 사용 (비용 절감)
# 금융 실제 운영 시 90일 이상 권장
# ─────────────────────────────────────────
resource "azurerm_log_analytics_workspace" "main" {
  name                = "${var.prefix}-log-workspace"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"  # 실제 사용량만큼 과금
  retention_in_days   = 30
  tags                = var.tags
}

# ─────────────────────────────────────────
# Diagnostic Settings : Container Apps Environment
# 챗봇 컨테이너 시스템 로그 수집
# ─────────────────────────────────────────
resource "azurerm_monitor_diagnostic_setting" "container_app_env" {
  name                       = "${var.prefix}-env-diag"
  target_resource_id         = azurerm_container_app_environment.main.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  # 시스템 로그 : Container Apps 인프라 동작 기록
  enabled_log {
    category = "ContainerAppSystemLogs"
  }

  # 콘솔 로그 : 챗봇 코드의 print/logging 출력
  # Python 코드에서 print("요청 받음") 하면 여기 쌓임
  enabled_log {
    category = "ContainerAppConsoleLogs"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

# ─────────────────────────────────────────
# Diagnostic Settings : Container App (chatbot)
# ContainerAppConsoleLogs/SystemLogs는 Environment 전용 카테고리
# Container App 리소스 레벨에서는 메트릭만 수집 가능
# ─────────────────────────────────────────
resource "azurerm_monitor_diagnostic_setting" "container_app" {
  name                       = "${var.prefix}-app-diag"
  target_resource_id         = azurerm_container_app.chatbot.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

# ─────────────────────────────────────────
# Diagnostic Settings : Key Vault
# 금융권 필수 - 누가 언제 어떤 시크릿 접근했는지 기록
# 감사(Audit) 목적
# ─────────────────────────────────────────
resource "azurerm_monitor_diagnostic_setting" "keyvault" {
  name                       = "${var.prefix}-kv-diag"
  target_resource_id         = azurerm_key_vault.main.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  # 감사 로그 : Key Vault 접근 기록
  # "Managed Identity가 openai-api-key를 조회함" 등
  enabled_log {
    category = "AuditEvent"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

# ─────────────────────────────────────────
# Diagnostic Settings : VPN Gateway
# VPN 터널 상태, 연결/끊김 기록
# AWS ↔ Azure 통신 문제 발생 시 원인 파악용
# ─────────────────────────────────────────
resource "azurerm_monitor_diagnostic_setting" "vpn_gateway" {
  name                       = "${var.prefix}-vpn-diag"
  target_resource_id         = azurerm_virtual_network_gateway.main.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  # VPN 터널 상태 로그
  enabled_log {
    category = "TunnelDiagnosticLog"
  }

  # IKE 협상 로그 : VPN 연결 수립 과정 기록
  # AWS VGW 연결 안 될 때 원인 파악에 필수
  enabled_log {
    category = "IKEDiagnosticLog"
  }

  # VPN Gateway 전체 진단 로그
  enabled_log {
    category = "GatewayDiagnosticLog"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

# ─────────────────────────────────────────
# Diagnostic Settings : Azure OpenAI
# API 호출 횟수, 토큰 사용량, 오류 기록
# 비용 모니터링 및 이상 감지용
# ─────────────────────────────────────────
resource "azurerm_monitor_diagnostic_setting" "openai" {
  name                       = "${var.prefix}-openai-diag"
  target_resource_id         = azurerm_cognitive_account.openai.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  # 감사 로그
  enabled_log {
    category = "Audit"
  }

  # 요청/응답 로그
  enabled_log {
    category = "RequestResponse"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}
