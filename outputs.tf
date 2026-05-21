# =========================================================
# RDS Outputs
# =========================================================

output "rds_endpoint" {
  description = "RDS MySQL endpoint with port"
  value = {
    for key, db in aws_db_instance.mysql :
    key => db.endpoint
  }

}

output "rds_addresses" {
  description = "RDS MySQL addresses by network"
  value = {
    for key, db in aws_db_instance.mysql :
    key => db.address
  }
}

output "rds_security_group_ids" {
  description = "RDS Security Group IDs by network"
  value = {
    for key, sg in aws_security_group.rds_mysql :
    key => sg.id
  }
}

# =========================================================
# Redis EC2 Outputs
# ElastiCache Endpoint가 아니라 EC2 Private IP/DNS 기준으로 출력
# =========================================================

output "redis_private_ips" {
  description = "Private IPs of Redis EC2 instances"
  value = {
    for key, instance in aws_instance.redis :
    key => instance.private_ip
  }
}

output "redis_private_dns" {
  description = "Private DNS names of Redis EC2 instances"
  value = {
    for key, instance in aws_instance.redis :
    key => instance.private_dns
  }
}

output "redis_instance_ids" {
  description = "EC2 instance IDs of Redis nodes"
  value = {
    for key, instance in aws_instance.redis :
    key => instance.id
  }
}

output "redis_security_group_ids" {
  description = "Redis Security Group IDs by network"
  value = {
    for key, sg in aws_security_group.redis :
    key => sg.id
  }
}

output "redis_nodes" {
  description = "Redis EC2 node connection information"
  value = {
    for key, instance in aws_instance.redis :
    key => {
      name        = var.redis_nodes[key].name
      network     = var.redis_nodes[key].network_key
      private_ip  = instance.private_ip
      private_dns = instance.private_dns
      instance_id = instance.id
      port        = var.redis_port
    }
  }
}