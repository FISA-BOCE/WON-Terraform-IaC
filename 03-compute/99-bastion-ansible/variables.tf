variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-2"
}

variable "ansible_bastion_ami_id" {
  description = "Ubuntu 24.04 LTS AMI ID for Ansible bastion EC2 instances"
  type        = string
  default     = "ami-0765f9741eedf9c7b"
}

variable "ansible_bastion_instance_type" {
  description = "Ansible bastion EC2 instance type"
  type        = string
  default     = "t3.small"
}

variable "default_tags" {
  description = "Default tags applied to compute resources"
  type        = map(string)
  default = {
    Project   = "WON-Terraform-IaC"
    ManagedBy = "Terraform"
  }
}
