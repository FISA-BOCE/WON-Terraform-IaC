locals {
  eks_clusters = {
    card = {
      cluster_name = "${var.project_name}-card-eks"
      vpc_key      = "card"

      private_subnet_keys = [
        "card-eks-cluster-private-subnet-01",
        "card-eks-cluster-private-subnet-02"
      ]

      node_group_name = "card-workload-ng"
    }

    securities = {
      cluster_name = "${var.project_name}-securities-eks"
      vpc_key      = "securities"

      private_subnet_keys = [
        "securities-eks-cluster-private-subnet-01",
        "securities-eks-cluster-private-subnet-02"
      ]

      node_group_name = "securities-workload-ng"
    }
  }

  eks_cluster_subnet_ids = {
    for cluster_key, cluster in local.eks_clusters :
    cluster_key => [
      for subnet_key in cluster.private_subnet_keys :
      data.terraform_remote_state.network.outputs.subnet_ids[subnet_key]
    ]
  }

  eks_subnet_tags = merge([
    for cluster_key, cluster in local.eks_clusters : {
      for subnet_key in cluster.private_subnet_keys :
      "${cluster_key}-${subnet_key}" => {
        cluster_key  = cluster_key
        cluster_name = cluster.cluster_name
        subnet_id    = data.terraform_remote_state.network.outputs.subnet_ids[subnet_key]
      }
    }
  ]...)

  ecr_repositories = {
    card = {
      name = "won-card-channel-server"
    }

    invest = {
      name = "won-invest-channel-server"
    }
  }
}
