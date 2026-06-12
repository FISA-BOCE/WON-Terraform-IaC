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

variable "enable_sqs" {
  description = "Whether to create SQS queues for the sweep workflow"
  type        = bool
  default     = true
}

variable "sqs_visibility_timeout_seconds" {
  description = "Visibility timeout for sweep SQS queues"
  type        = number
  default     = 360
}

variable "sqs_message_retention_seconds" {
  description = "Message retention period for sweep SQS queues and DLQs"
  type        = number
  default     = 1209600
}

variable "sqs_receive_wait_time_seconds" {
  description = "Long polling wait time for sweep SQS queues"
  type        = number
  default     = 10
}

variable "sqs_max_receive_count" {
  description = "Number of receives before moving a message to the DLQ"
  type        = number
  default     = 5
}

variable "eks_node_role_names" {
  description = "EKS node IAM role names that need access to the sweep SQS queues"
  type        = map(string)

  default = {
    card       = "won-card-eks-node-role"
    securities = "won-securities-eks-node-role"
  }
}

variable "default_tags" {
  description = "Default tags applied to SQS resources"
  type        = map(string)
  default = {
    Project   = "WON-Terraform-IaC"
    ManagedBy = "Terraform"
  }
}
