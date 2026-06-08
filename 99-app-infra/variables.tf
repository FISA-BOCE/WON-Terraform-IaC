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

# =========================================================
# EC2 Common
# Redis EC2에서 공통으로 사용하는 값
# =========================================================

variable "ec2_ami_id" {
  description = "Ubuntu 24.04 LTS AMI ID for Redis EC2 instances"
  type        = string
  default     = "ami-0765f9741eedf9c7b"
}

variable "ec2_key_name" {
  description = "EC2 key pair name"
  type        = string
  default     = "boce-keypair"
}

variable "ec2_associate_public_ip_address" {
  description = "Whether to associate public IP address to EC2 instances"
  type        = bool
  default     = false
}

# =========================================================
# Redis EC2
# =========================================================

variable "enable_redis" {
  description = "Whether to create Redis EC2 nodes and Redis security groups"
  type        = bool
  default     = false
}

variable "redis_instance_type" {
  description = "EC2 instance type for Redis nodes"
  type        = string
  default     = "m6i.large"
}

variable "redis_root_volume_size" {
  description = "Root EBS volume size for Redis EC2 instances"
  type        = number
  default     = 10
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

variable "redis_password" {
  description = "Redis password used in redis.conf requirepass"
  type        = string
  sensitive   = true
  default     = null
}

# =========================================================
# Redis Networks
# 카드망 / 증권망 Redis가 각각 어떤 VPC와 SG를 쓰는지 정의
# 실제 값은 terraform.tfvars에 넣음
# =========================================================

variable "redis_networks" {
  description = "Network definitions for Redis EC2 nodes"
  type = map(object({
    vpc_name = string
    vpc_cidr = string
  }))
  default = {}
}

# =========================================================
# Redis Nodes
# 카드 Redis 3대 + 증권 Redis 3대를 같은 redis.tf에서 for_each로 생성
# =========================================================

variable "redis_nodes" {
  description = "Redis EC2 node definitions"
  type = map(object({
    name        = string
    network_key = string
    subnet_name = string
    subnet_cidr = string
    private_ip  = string
  }))
  default = {}
}
