locals {
  wireguard_routes = {
    card = {
      destination_cidr      = "10.1.100.0/24"
      active_wireguard_name = "card-wireguard-01"
      associated_subnet_keys = [
        "card-dmz-private-subnet",
        "card-eks-cluster-private-subnet-01",
        "card-eks-cluster-private-subnet-02",
        "card-data-layer-private-subnet-01",
        "card-data-layer-private-subnet-02",
        "card-ai-db-private-subnet"
      ]
    }
    securities = {
      destination_cidr      = "10.1.200.0/24"
      active_wireguard_name = "securities-wireguard-01"
      associated_subnet_keys = [
        "securities-dmz-private-subnet",
        "securities-eks-cluster-private-subnet-01",
        "securities-eks-cluster-private-subnet-02",
        "securities-data-layer-private-subnet-01",
        "securities-data-layer-private-subnet-02",
        "securities-ai-db-private-subnet"
      ]
    }
  }

  wireguard_route_table_associations = merge([
    for vpc_key, route in local.wireguard_routes : {
      for subnet_key in route.associated_subnet_keys : subnet_key => {
        vpc_key    = vpc_key
        subnet_key = subnet_key
      }
    }
  ]...)
}

resource "aws_route_table" "wireguard" {
  for_each = local.wireguard_routes

  vpc_id = data.terraform_remote_state.network.outputs.vpc_ids[each.key]

  tags = merge(var.default_tags, {
    Name = "${each.key}-wireguard-rt"
    Vpc  = each.key
  })
}

resource "aws_route" "to_onprem_via_wireguard" {
  for_each = local.wireguard_routes

  route_table_id         = aws_route_table.wireguard[each.key].id
  destination_cidr_block = each.value.destination_cidr
  network_interface_id   = aws_network_interface.wireguard[each.value.active_wireguard_name].id
}

resource "aws_route_table_association" "wireguard" {
  for_each = local.wireguard_route_table_associations

  subnet_id      = data.terraform_remote_state.network.outputs.subnet_ids[each.value.subnet_key]
  route_table_id = aws_route_table.wireguard[each.value.vpc_key].id
}
