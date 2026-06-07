resource "kubernetes_namespace" "argocd_card" {
  provider = kubernetes.card

  metadata {
    name = "argocd"
  }

  depends_on = [
    aws_eks_node_group.workload
  ]
}

resource "kubernetes_namespace" "argocd_securities" {
  provider = kubernetes.securities

  metadata {
    name = "argocd"
  }

  depends_on = [
    aws_eks_node_group.workload
  ]
}

resource "helm_release" "argocd_card" {
  provider = helm.card

  name       = "argocd"
  namespace  = kubernetes_namespace.argocd_card.metadata[0].name
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = var.argocd_chart_version

  values = [
    yamlencode({
      server = {
        service = {
          type = "ClusterIP"
        }
      }
      configs = {
        params = {
          "server.insecure" = false
        }
      }
    })
  ]

  depends_on = [
    kubernetes_namespace.argocd_card
  ]
}

resource "helm_release" "argocd_securities" {
  provider = helm.securities

  name       = "argocd"
  namespace  = kubernetes_namespace.argocd_securities.metadata[0].name
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = var.argocd_chart_version

  values = [
    yamlencode({
      server = {
        service = {
          type = "ClusterIP"
        }
      }
      configs = {
        params = {
          "server.insecure" = false
        }
      }
    })
  ]

  depends_on = [
    kubernetes_namespace.argocd_securities
  ]
}
