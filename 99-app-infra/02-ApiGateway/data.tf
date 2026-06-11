data "aws_region" "current" {}

data "terraform_remote_state" "loadbalancer" {
  backend = "local"

  config = {
    path = var.loadbalancer_state_path
  }
}
