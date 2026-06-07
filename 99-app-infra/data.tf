data "terraform_remote_state" "eks" {
  backend = "local"

  config = {
    path = var.eks_state_path
  }
}
