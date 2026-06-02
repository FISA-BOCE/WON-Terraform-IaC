output "ai_db_instance_ids" {
  description = "AI DB EC2 instance IDs by instance name"
  value = {
    for key, instance in aws_instance.ai_db : key => instance.id
  }
}

output "ai_db_private_ips" {
  description = "AI DB EC2 private IPs by instance name"
  value = {
    for key, instance in aws_instance.ai_db : key => instance.private_ip
  }
}

output "ai_db_subnet_ids" {
  description = "AI DB subnet IDs by instance name"
  value = {
    for key, config in local.ai_db_instances : key => data.terraform_remote_state.network.outputs.subnet_ids[config.subnet_key]
  }
}

output "ai_db_security_group_ids" {
  description = "AI DB security group IDs used by instance name"
  value = {
    for key, config in local.ai_db_instances : key => data.terraform_remote_state.security.outputs.ai_db_security_group_ids[config.vpc_key]
  }
}
