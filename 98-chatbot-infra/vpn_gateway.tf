# ─────────────────────────────────────────
# VPN Gateway용 Public IP
# VpnGw1AZ = Standard Static 필수
# ─────────────────────────────────────────
resource "azurerm_public_ip" "vpn_gateway" {
  name                = "${var.prefix}-vpn-gw-pip"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"   # Standard SKU는 Static 필요
  sku                 = "Standard"
  zones               = ["1", "2", "3"]  # AZ SKU는 Zone 지정 필요
  tags                = var.tags
}

# ─────────────────────────────────────────
# VPN Gateway
# VpnGw1AZ: Azure가 VpnGw1 이상 비-AZ SKU 지원 종료
# Active-Standby, BGP 미사용
# ─────────────────────────────────────────
resource "azurerm_virtual_network_gateway" "main" {
  name                = "${var.prefix}-vpn-gw"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  type     = "Vpn"
  vpn_type = "RouteBased"

  sku           = "VpnGw1AZ"
  active_active = false
  enable_bgp    = false

  ip_configuration {
    name                          = "vpn-gw-ip-config"
    public_ip_address_id          = azurerm_public_ip.vpn_gateway.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.gateway.id
  }

  tags = var.tags
}

# ─────────────────────────────────────────
# Local Network Gateway (AWS VGW 정보 등록)
# ─────────────────────────────────────────
resource "azurerm_local_network_gateway" "aws" {
  name                = "${var.prefix}-aws-local-gw"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  gateway_address     = var.aws_vpn_public_ip
  address_space       = var.aws_address_spaces
  tags                = var.tags
}

# ─────────────────────────────────────────
# VPN Connection
# ─────────────────────────────────────────
resource "azurerm_virtual_network_gateway_connection" "aws" {
  name                = "${var.prefix}-aws-vpn-connection"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  type                       = "IPsec"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.main.id
  local_network_gateway_id   = azurerm_local_network_gateway.aws.id
  shared_key                 = var.vpn_shared_key

  ipsec_policy {
    dh_group         = "DHGroup2"
    ike_encryption   = "AES128"
    ike_integrity    = "SHA1"
    ipsec_encryption = "AES128"
    ipsec_integrity  = "SHA1"
    pfs_group        = "PFS2"
    sa_lifetime      = 3600
    sa_datasize      = 102400000
  }
  tags = var.tags


}
