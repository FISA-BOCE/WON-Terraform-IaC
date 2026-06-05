output "eks_cluster_names" {
  value = {
    for key, cluster in aws_eks_cluster.this :
    key => cluster.name
  }
}

output "eks_cluster_endpoints" {
  value = {
    for key, cluster in aws_eks_cluster.this :
    key => cluster.endpoint
  }
}

output "eks_cluster_security_group_ids" {
  value = {
    for key, cluster in aws_eks_cluster.this :
    key => cluster.vpc_config[0].cluster_security_group_id
  }
}

output "eks_node_group_names" {
  value = {
    for key, node_group in aws_eks_node_group.workload :
    key => node_group.node_group_name
  }
}

output "ecr_repository_urls" {
  value = {
    for key, repo in aws_ecr_repository.channel :
    key => repo.repository_url
  }
}
