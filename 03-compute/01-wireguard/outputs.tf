output "wireguard_instance_ids" {
  description = "WireGuard EC2 instance IDs by instance name"
  value = {
    for key, instance in aws_instance.wireguard : key => instance.id
  }
}

output "wireguard_private_ips" {
  description = "WireGuard EC2 private IPs by instance name"
  value = {
    for key, eni in aws_network_interface.wireguard : key => eni.private_ip
  }
}

output "wireguard_public_ips" {
  description = "WireGuard EC2 Elastic IPs by instance name"
  value = {
    for key, eip in aws_eip.wireguard : key => eip.public_ip
  }
}

output "wireguard_primary_network_interface_ids" {
  description = "WireGuard EC2 primary network interface IDs by instance name"
  value = {
    for key, eni in aws_network_interface.wireguard : key => eni.id
  }
}

output "wireguard_security_group_ids" {
  description = "WireGuard security group IDs used by VPC key"
  value       = data.terraform_remote_state.security.outputs.wg_security_group_ids
}

output "wireguard_iam_role_name" {
  description = "IAM role name attached to WireGuard EC2 instances"
  value       = aws_iam_role.wg_ha.name
}

output "wireguard_iam_instance_profile_name" {
  description = "IAM instance profile name attached to WireGuard EC2 instances"
  value       = aws_iam_instance_profile.wg_ha.name
}

output "wireguard_route_table_ids" {
  description = "WireGuard route table IDs by VPC key"
  value = {
    for key, route_table in aws_route_table.wireguard : key => route_table.id
  }
}

output "wireguard_route_destination_cidrs" {
  description = "WireGuard route destination CIDR blocks by VPC key"
  value = {
    for key, route in local.wireguard_routes : key => route.destination_cidr
  }
}

output "wireguard_active_network_interface_ids" {
  description = "Initial active WireGuard ENI IDs by VPC key"
  value = {
    for key, route in local.wireguard_routes : key => aws_network_interface.wireguard[route.active_wireguard_name].id
  }
}
