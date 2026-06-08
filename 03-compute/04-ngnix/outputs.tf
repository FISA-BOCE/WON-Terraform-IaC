output "ngnix_instance_ids" {
  description = "Nginx EC2 instance IDs by instance name"
  value = {
    for key, instance in aws_instance.ngnix : key => instance.id
  }
}

output "ngnix_private_ips" {
  description = "Nginx EC2 private IPs by instance name"
  value = {
    for key, instance in aws_instance.ngnix : key => instance.private_ip
  }
}

output "ngnix_subnet_ids" {
  description = "Nginx subnet IDs by instance name"
  value = {
    for key, config in local.ngnix_instances : key => data.terraform_remote_state.network.outputs.subnet_ids[config.subnet_key]
  }
}

output "ngnix_security_group_ids" {
  description = "Nginx security group IDs used by instance name"
  value = {
    for key, config in local.ngnix_instances : key => data.terraform_remote_state.security.outputs.nginx_security_group_ids[config.vpc_key]
  }
}
