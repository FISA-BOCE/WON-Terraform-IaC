variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-2"
}

variable "network_state_path" {
  description = "Path to the network Terraform state used to load VPC and subnet IDs"
  type        = string
  default     = "../../01-network/terraform.tfstate"
}

variable "loadbalancer_state_path" {
  description = "Path to the load balancer Terraform state used to load NLB ARNs"
  type        = string
  default     = "../../04-loadbalancer/terraform.tfstate"
}

variable "endpoint_listener_port" {
  description = "TCP port allowed to the interface endpoints"
  type        = number
  default     = 80
}

variable "default_tags" {
  description = "Default tags applied to PrivateLink resources"
  type        = map(string)
  default = {
    Project   = "WON-Terraform-IaC"
    ManagedBy = "Terraform"
  }
}
