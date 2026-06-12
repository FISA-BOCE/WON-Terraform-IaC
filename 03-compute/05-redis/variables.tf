variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-2"
}

variable "project" {
  description = "Project name"
  type        = string
  default     = "wonhaeyo"
}

variable "env" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "network_state_path" {
  description = "Path to the network Terraform state used to load VPC and subnet IDs"
  type        = string
  default     = "../../01-network/terraform.tfstate"
}

variable "eks_state_path" {
  description = "Path to the EKS Terraform state used to allow EKS security groups to access Redis"
  type        = string
  default     = "../03-eks/terraform.tfstate"
}

variable "app_infra_state_path" {
  description = "Path to the app infra Terraform state used to load application security groups"
  type        = string
  default     = "../../99-app-infra/terraform.tfstate"
}

variable "redis_ami_id" {
  description = "Ubuntu 24.04 LTS AMI ID for Redis EC2 instances"
  type        = string
  default     = "ami-0765f9741eedf9c7b"
}

variable "redis_instance_type" {
  description = "EC2 instance type for Redis nodes"
  type        = string
  default     = "t3.small"
}

variable "redis_root_volume_size" {
  description = "Root EBS volume size for Redis EC2 instances"
  type        = number
  default     = 20
}

variable "redis_root_volume_type" {
  description = "Root EBS volume type for Redis EC2 instances"
  type        = string
  default     = "gp3"
}

variable "redis_port" {
  description = "Redis service port"
  type        = number
  default     = 6379
}

variable "redis_sentinel_port" {
  description = "Redis Sentinel service port"
  type        = number
  default     = 26379
}

variable "redis_networks" {
  description = "Network definitions for Redis Sentinel HA groups"
  type = map(object({
    vpc_key                        = string
    sentinel_master_name           = string
    master_node_key                = string
    ssh_allowed_cidrs              = optional(list(string), [])
    ssh_allowed_security_group_ids = optional(list(string), [])
  }))
}

variable "redis_nodes" {
  description = "Redis EC2 node definitions"
  type = map(object({
    name        = string
    network_key = string
    subnet_key  = string
    private_ip  = string
  }))
}

variable "default_tags" {
  description = "Default tags applied to compute resources"
  type        = map(string)
  default = {
    Project   = "WON-Terraform-IaC"
    ManagedBy = "Terraform"
  }
}
