output "redis_private_ips" {
  description = "Private IPs of Redis EC2 instances"
  value = merge([
    for network_key, module_instance in module.redis_sentinel :
    module_instance.private_ips
  ]...)
}

output "redis_private_dns" {
  description = "Private DNS names of Redis EC2 instances"
  value = merge([
    for network_key, module_instance in module.redis_sentinel :
    module_instance.private_dns
  ]...)
}

output "redis_instance_ids" {
  description = "EC2 instance IDs of Redis nodes"
  value = merge([
    for network_key, module_instance in module.redis_sentinel :
    module_instance.instance_ids
  ]...)
}

output "redis_security_group_ids" {
  description = "Redis Security Group IDs by network"
  value = {
    for key, module_instance in module.redis_sentinel :
    key => module_instance.redis_security_group_id
  }
}

output "redis_nodes" {
  description = "Redis EC2 node connection information"
  value = merge([
    for network_key, module_instance in module.redis_sentinel :
    {
      for node_key, node in module_instance.node_details :
      node_key => merge(node, {
        network = network_key
        port    = node.redis_port
      })
    }
  ]...)
}

output "redis_private_ips_by_network" {
  description = "Redis private IP lists grouped by network"
  value = {
    for network_key, module_instance in module.redis_sentinel :
    network_key => values(module_instance.private_ips)
  }
}

output "redis_sentinel_endpoints" {
  description = "Redis Sentinel endpoints grouped by network"
  value = {
    for network_key, module_instance in module.redis_sentinel :
    network_key => values(module_instance.sentinel_endpoints)
  }
}

output "redis_sentinel_master_names" {
  description = "Redis Sentinel master names grouped by network"
  value = {
    for network_key, module_instance in module.redis_sentinel :
    network_key => module_instance.sentinel_master_name
  }
}
