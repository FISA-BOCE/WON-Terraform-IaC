# ─────────────────────────────────────────
# VNet
# ─────────────────────────────────────────
resource "azurerm_virtual_network" "main" {
  name                = "${var.prefix}-vnet"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = [var.vnet_cidr]
  tags                = var.tags
}

# ─────────────────────────────────────────
# 서브넷 1 : GatewaySubnet
# - 이름 "GatewaySubnet" 은 Azure 규칙상 변경 불가
# - VPN Gateway 전용 서브넷
# ─────────────────────────────────────────
resource "azurerm_subnet" "gateway" {
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.gateway_subnet_cidr]
}

# ─────────────────────────────────────────
# 서브넷 2 : Container Apps Subnet
# - Azure 강제 최솟값 /23
# - delegation 필수: Azure가 이 서브넷을
#   Container Apps 전용으로 관리하겠다고 선언
# - NSG 연결
# ─────────────────────────────────────────
resource "azurerm_subnet" "container_apps" {
  name                 = "${var.prefix}-container-apps-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.container_apps_subnet_cidr]

  # Container Apps 전용 서브넷으로 위임
  # 이 설정 없으면 Container Apps Environment 배포 실패
  delegation {
    name = "container-apps-delegation"
    service_delegation {
      name = "Microsoft.App/environments"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action"
      ]
    }
  }
}

# ─────────────────────────────────────────
# 서브넷 3 : Private Endpoint Subnet
# - OpenAI PE, Key Vault PE 배치
# - private_endpoint_network_policies = "Disabled"
#   Private Endpoint가 NSG/UDR 정책을 무시하고
#   동작할 수 있도록 설정 (Azure PE 필수 조건)
# ─────────────────────────────────────────
resource "azurerm_subnet" "private_endpoint" {
  name                 = "${var.prefix}-pe-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.pe_subnet_cidr]

  private_endpoint_network_policies = "Disabled"
}

# ─────────────────────────────────────────
# NSG (Network Security Group)
# AppGw 제거 후 서브넷 레벨 방화벽 역할
# Container Apps Subnet에 적용
# ─────────────────────────────────────────
resource "azurerm_network_security_group" "container_apps" {
  name                = "${var.prefix}-container-apps-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags

  # ── 인바운드 규칙 ──────────────────────

  # AWS VPN 트래픽만 허용 (GatewaySubnet에서 오는 요청)
  # 챗봇 API 호출 진입점
  security_rule {
    name                       = "Allow-VPN-Inbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = var.gateway_subnet_cidr  # 10.41.11.0/24
    destination_address_prefix = "*"
  }

  # Azure 로드밸런서 헬스체크 허용
  # 이 규칙 없으면 Container Apps 내부 상태 확인 불가
  security_rule {
    name                       = "Allow-AzureLoadBalancer"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "AzureLoadBalancer"
    destination_address_prefix = "*"
  }

  # 위 규칙 외 모든 인바운드 차단
  security_rule {
    name                       = "Deny-All-Inbound"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # ── 아웃바운드 규칙 ────────────────────

  # OpenAI, Key Vault Private Endpoint 호출 허용
  security_rule {
    name                       = "Allow-PrivateEndpoint-Outbound"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = var.pe_subnet_cidr  # 10.41.31.0/24
  }

  # Container Apps 관리 플레인 통신 허용
  # Azure가 Container Apps 상태 모니터링, 배포 관리에 사용
  security_rule {
    name                       = "Allow-AzureCloud-Outbound"
    priority                   = 110
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "AzureCloud"
  }

  # Graph DB 조회용 (VPN 통해 AWS로 나가는 트래픽)
  # Neo4j Bolt 프로토콜 포트 (Python Driver 통신)
  # PrivateLink 구조상 공통VPC Interface Endpoint IP로 통신
  # 실제 목적지는 공통VPC 대역(10.31.x.x)
  security_rule {
    name                       = "Allow-Neo4j-Outbound"
    priority                   = 120
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "7687"   # Neo4j Bolt 프로토콜 포트
    source_address_prefix      = "*"
    destination_address_prefix = "10.31.0.0/16"  # 공통VPC (PrivateLink 허브)
  }

  # DNS 조회 허용 (도메인 → IP 변환, Private Endpoint DNS 포함)
  security_rule {
    name                       = "Allow-DNS-Outbound"
    priority                   = 140
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "*"
    destination_port_range     = "53"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # MySQL 아웃바운드 (공통VPC PrivateLink 통해 접근)
  security_rule {
    name                       = "Allow-AWS-MySQL-Outbound"
    priority                   = 150
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3306"
    source_address_prefix      = "*"
    destination_address_prefix = "10.31.0.0/16"
  }
}

# NSG를 Container Apps Subnet에 연결
resource "azurerm_subnet_network_security_group_association" "container_apps" {
  subnet_id                 = azurerm_subnet.container_apps.id
  network_security_group_id = azurerm_network_security_group.container_apps.id
}
