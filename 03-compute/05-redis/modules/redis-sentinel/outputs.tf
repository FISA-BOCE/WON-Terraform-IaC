output "instance_ids" {
  description = "Redis EC2 instance IDs by node key"
  value = {
    for key, instance in aws_instance.this : key => instance.id
  }
}

output "private_ips" {
  description = "Redis private IPs by node key"
  value = {
    for key, instance in aws_instance.this : key => instance.private_ip
  }
}

output "private_dns" {
  description = "Redis private DNS names by node key"
  value = {
    for key, instance in aws_instance.this : key => instance.private_dns
  }
}

output "sentinel_endpoints" {
  description = "Sentinel endpoints by node key"
  value = {
    for key, instance in aws_instance.this : key => "${instance.private_ip}:${var.sentinel_port}"
  }
}

output "node_details" {
  description = "Redis node details by node key"
  value = {
    for key, instance in aws_instance.this : key => {
      name              = var.nodes[key].name
      private_ip        = instance.private_ip
      private_dns       = instance.private_dns
      instance_id       = instance.id
      redis_port        = var.redis_port
      sentinel_port     = var.sentinel_port
      sentinel_endpoint = "${instance.private_ip}:${var.sentinel_port}"
      role              = var.nodes[key].is_master ? "master" : "replica"
    }
  }
}

output "redis_security_group_id" {
  description = "Redis Sentinel HA security group ID"
  value       = aws_security_group.this.id
}

output "sentinel_master_name" {
  description = "Sentinel master name for the network"
  value       = var.sentinel_master_name
}
