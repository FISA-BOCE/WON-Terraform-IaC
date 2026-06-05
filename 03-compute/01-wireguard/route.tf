locals {
  wireguard_routes = {
    card = {
      destination_cidr      = "10.1.100.0/24"
      active_wireguard_name = "card-wireguard-01"
    }
    securities = {
      destination_cidr      = "10.1.200.0/24"
      active_wireguard_name = "securities-wireguard-01"
    }
  }
}

resource "aws_route" "to_onprem_via_wireguard" {
  for_each = local.wireguard_routes

  route_table_id         = data.terraform_remote_state.network.outputs.private_route_table_ids[each.key]
  destination_cidr_block = each.value.destination_cidr
  network_interface_id   = aws_network_interface.wireguard[each.value.active_wireguard_name].id

  lifecycle {
    ignore_changes = [
      network_interface_id
    ]
  }
}
