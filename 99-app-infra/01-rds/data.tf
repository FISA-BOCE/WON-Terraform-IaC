data "terraform_remote_state" "eks" {
  backend = "local"

  config = {
    path = var.eks_state_path
  }
}

data "terraform_remote_state" "network" {
  backend = "local"

  config = {
    path = var.network_state_path
  }
}
