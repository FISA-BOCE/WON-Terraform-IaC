variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-2"
}

variable "project_name" {
  description = "Project name prefix"
  type        = string
  default     = "won"
}

variable "eks_cluster_version" {
  description = "EKS Kubernetes version"
  type        = string
  default     = "1.30"
}

variable "node_instance_types" {
  description = "EKS node instance types"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_desired_size" {
  type    = number
  default = 2
}

variable "node_min_size" {
  type    = number
  default = 2
}

variable "node_max_size" {
  type    = number
  default = 4
}

variable "argocd_chart_version" {
  description = "ArgoCD Helm chart version"
  type        = string
  default     = "7.6.12"
}

variable "default_tags" {
  description = "Default tags"
  type        = map(string)

  default = {
    Project   = "WON-Terraform-IaC"
    ManagedBy = "Terraform"
  }
}
