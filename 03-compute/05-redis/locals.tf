locals {
  redis_nodes_by_network = {
    for network_key, network in var.redis_networks : network_key => {
      for node_key, node in var.redis_nodes : node_key => {
        name       = node.name
        subnet_id  = data.terraform_remote_state.network.outputs.subnet_ids[node.subnet_key]
        private_ip = node.private_ip
        is_master  = node_key == network.master_node_key
      } if node.network_key == network_key
    }
  }
}
