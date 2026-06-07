data "terraform_remote_state" "network" {
  backend = "local"

  config = {
    path = "../../01-network/terraform.tfstate"
  }
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_eks_cluster_auth" "card" {
  name = aws_eks_cluster.this["card"].name
}

data "aws_eks_cluster_auth" "securities" {
  name = aws_eks_cluster.this["securities"].name
}
