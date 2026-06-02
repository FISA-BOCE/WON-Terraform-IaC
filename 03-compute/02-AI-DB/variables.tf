variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-2"
}

variable "ai_db_ami_id" {
  description = "Ubuntu 24.04 LTS AMI ID for AI DB EC2 instances"
  type        = string
  default     = "ami-0765f9741eedf9c7b"
}

variable "ai_db_instance_type" {
  description = "AI DB EC2 instance type"
  type        = string
  default     = "m6i.large"
}

variable "default_tags" {
  description = "Default tags applied to compute resources"
  type        = map(string)
  default = {
    Project   = "WON-Terraform-IaC"
    ManagedBy = "Terraform"
  }
}
