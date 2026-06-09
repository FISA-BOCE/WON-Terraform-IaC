variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-2"
}

variable "api_name" {
  description = "REST API Gateway name"
  type        = string
  default     = "BOCE-api-gateway"
}

variable "stage_name" {
  description = "REST API Gateway deployment stage name"
  type        = string
  default     = "dev"
}

variable "ngnix_listener_port" {
  description = "Nginx NLB listener port"
  type        = number
  default     = 80
}

variable "loadbalancer_state_path" {
  description = "Path to the load balancer Terraform state"
  type        = string
  default     = "../../04-loadbalancer/terraform.tfstate"
}

variable "access_log_retention_days" {
  description = "CloudWatch retention days for API Gateway access logs"
  type        = number
  default     = 30
}

variable "default_tags" {
  description = "Default tags applied to API Gateway resources"
  type        = map(string)
  default = {
    Project   = "WON-Terraform-IaC"
    ManagedBy = "Terraform"
  }
}
