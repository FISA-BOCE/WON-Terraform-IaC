output "ansible_bastion_instance_ids" {
  description = "Ansible bastion EC2 instance IDs by instance name"
  value = {
    for key, instance in aws_instance.ansible_bastion : key => instance.id
  }
}

output "ansible_bastion_private_ips" {
  description = "Ansible bastion EC2 private IPs by instance name"
  value = {
    for key, instance in aws_instance.ansible_bastion : key => instance.private_ip
  }
}

output "ansible_bastion_public_ips" {
  description = "Ansible bastion EC2 public IPs by instance name"
  value = {
    for key, instance in aws_instance.ansible_bastion : key => instance.public_ip
  }
}
