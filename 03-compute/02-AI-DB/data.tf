data "terraform_remote_state" "network" {
  backend = "local"

  config = {
    path = "../../01-network/terraform.tfstate"
  }
}

data "terraform_remote_state" "security" {
  backend = "local"

  config = {
    path = "../../02-security/terraform.tfstate"
  }
}
