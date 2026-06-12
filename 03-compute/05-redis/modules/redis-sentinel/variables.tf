variable "project" {
  description = "Project name"
  type        = string
}

variable "env" {
  description = "Environment name"
  type        = string
}

variable "network_key" {
  description = "Logical network key such as card or securities"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where Redis instances will be deployed"
  type        = string
}

variable "ami_id" {
  description = "AMI ID for Redis EC2 instances"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for Redis instances"
  type        = string
}

variable "key_name" {
  description = "EC2 key pair name"
  type        = string
}

variable "associate_public_ip_address" {
  description = "Whether to associate public IPs to Redis instances"
  type        = bool
  default     = false
}

variable "root_volume_size" {
  description = "Root volume size in GiB"
  type        = number
}

variable "root_volume_type" {
  description = "Root volume type"
  type        = string
}

variable "redis_port" {
  description = "Redis service port"
  type        = number
  default     = 6379
}

variable "sentinel_port" {
  description = "Redis Sentinel port"
  type        = number
  default     = 26379
}

variable "sentinel_master_name" {
  description = "Sentinel master name used by applications"
  type        = string
}

variable "nodes" {
  description = "Redis node definitions for a single network"
  type = map(object({
    name       = string
    subnet_id  = string
    private_ip = string
    is_master  = bool
  }))
}

variable "allowed_source_security_group_ids" {
  description = "Security groups allowed to access Redis and Sentinel"
  type        = list(string)
  default     = []
}

variable "ssh_allowed_cidrs" {
  description = "CIDR blocks allowed to SSH to Redis instances"
  type        = list(string)
  default     = []
}

variable "ssh_allowed_security_group_ids" {
  description = "Security groups allowed to SSH to Redis instances"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
