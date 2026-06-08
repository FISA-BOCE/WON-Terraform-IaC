variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-2"
}

variable "ngnix_ami_id" {
  description = "Ubuntu 24.04 LTS AMI ID for Nginx EC2 instances"
  type        = string
  default     = "ami-0765f9741eedf9c7b"
}

variable "ngnix_instance_type" {
  description = "Nginx EC2 instance type"
  type        = string
  default     = "t3.small"
}

variable "ngnix_root_volume_size" {
  description = "Root EBS volume size for Nginx EC2 instances"
  type        = number
  default     = 20
}

variable "default_tags" {
  description = "Default tags applied to compute resources"
  type        = map(string)
  default = {
    Project   = "WON-Terraform-IaC"
    ManagedBy = "Terraform"
  }
}
