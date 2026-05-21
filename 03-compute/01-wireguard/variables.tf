variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-2"
}

variable "project_name" {
  description = "Project name prefix for WireGuard IAM resources"
  type        = string
  default     = "boce"
}

variable "wireguard_ami_id" {
  description = "Ubuntu 24.04 LTS AMI ID for WireGuard EC2 instances"
  type        = string
  default     = "ami-0765f9741eedf9c7b"
}

variable "wireguard_instance_type" {
  description = "WireGuard EC2 instance type"
  type        = string
  default     = "c6i.large"
}

variable "default_tags" {
  description = "Default tags applied to compute resources"
  type        = map(string)
  default = {
    Project   = "WON-Terraform-IaC"
    ManagedBy = "Terraform"
  }
}
