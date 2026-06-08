data "terraform_remote_state" "network" {
  backend = "local"

  config = {
    path = "../01-network/terraform.tfstate"
  }
}

data "terraform_remote_state" "ngnix" {
  backend = "local"

  config = {
    path = "../03-compute/04-ngnix/terraform.tfstate"
  }
}
