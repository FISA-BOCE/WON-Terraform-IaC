# =========================================================
# Common
# =========================================================

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

# =========================================================
# Network - Existing VPC / Subnet / Security Group
# =========================================================

variable "rds_databases" {
  description = "RDS database definitions for card and securities. VPC and subnet IDs are loaded from the 01-network remote state."
  type = map(object({
    db_name     = string
    db_username = string
  }))
  default = {}
}

variable "rds_networks" {
  description = "Optional explicit RDS network definitions. When set, these values are used instead of deriving VPC and subnet IDs from remote state."
  type = map(object({
    vpc_id          = string
    data_subnet_ids = list(string)
    db_name         = string
    db_username     = string
  }))
  default = {}
}

variable "network_state_path" {
  description = "Path to the network Terraform state used to load VPC and subnet IDs"
  type        = string
  default     = "../01-network/terraform.tfstate"
}

variable "eks_state_path" {
  description = "Path to the EKS Terraform state used to allow EKS security groups to access RDS"
  type        = string
  default     = "../03-compute/03-eks/terraform.tfstate"
}

variable "db_passwords" {
  description = "RDS passwords by network"
  type        = map(string)
  sensitive   = true
}

# =========================================================
# RDS - Keep Existing RDS Variables
# =========================================================


variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t4g.micro"
}

variable "allocated_storage" {
  description = "Allocated storage size for RDS"
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "Maximum allocated storage size for RDS autoscaling"
  type        = number
  default     = 100
}

variable "rds_multi_az" {
  description = "Whether to enable Multi-AZ for RDS"
  type        = bool
  default     = true
}
