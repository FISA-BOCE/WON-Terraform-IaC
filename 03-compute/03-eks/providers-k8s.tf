provider "kubernetes" {
  alias = "card"

  host                   = aws_eks_cluster.this["card"].endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.this["card"].certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.card.token
}

provider "kubernetes" {
  alias = "securities"

  host                   = aws_eks_cluster.this["securities"].endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.this["securities"].certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.securities.token
}

provider "helm" {
  alias = "card"

  kubernetes {
    host                   = aws_eks_cluster.this["card"].endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.this["card"].certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.card.token
  }
}

provider "helm" {
  alias = "securities"

  kubernetes {
    host                   = aws_eks_cluster.this["securities"].endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.this["securities"].certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.securities.token
  }
}
