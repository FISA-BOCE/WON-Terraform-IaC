output "wg_security_group_ids" {
  description = "WireGuard security group IDs by VPC key"
  value = {
    for key, security_group in aws_security_group.wg : key => security_group.id
  }
}

output "wg_security_group_names" {
  description = "WireGuard security group names by VPC key"
  value = {
    for key, security_group in aws_security_group.wg : key => security_group.name
  }
}

output "test_security_group_ids" {
  description = "Private test EC2 security group IDs by VPC key"
  value = {
    for key, security_group in aws_security_group.test : key => security_group.id
  }
}

output "test_security_group_names" {
  description = "Private test EC2 security group names by VPC key"
  value = {
    for key, security_group in aws_security_group.test : key => security_group.name
  }
}

output "ansible_bastion_server_security_group_ids" {
  description = "Ansible bastion server EC2 security group IDs by VPC key"
  value = {
    for key, security_group in aws_security_group.ansible_bastion_server : key => security_group.id
  }
}

output "ansible_bastion_server_security_group_names" {
  description = "Ansible bastion server EC2 security group names by VPC key"
  value = {
    for key, security_group in aws_security_group.ansible_bastion_server : key => security_group.name
  }
}

output "vpc_ids" {
  description = "VPC IDs where security groups are created"
  value = {
    for key, vpc in local.vpcs : key => vpc.id
  }
}
