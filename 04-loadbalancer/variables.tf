variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-2"
}

variable "ngnix_listener_port" {
  description = "Nginx NLB listener and target port"
  type        = number
  default     = 80
}

variable "default_tags" {
  description = "Default tags applied to load balancer resources"
  type        = map(string)
  default = {
    Project   = "WON-Terraform-IaC"
    ManagedBy = "Terraform"
  }
}
