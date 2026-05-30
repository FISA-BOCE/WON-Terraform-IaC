data "terraform_remote_state" "network" {
  backend = "local"

  config = {
    path = "../01-network/terraform.tfstate"
  }
}

locals {
  vpcs = {
    for key, id in data.terraform_remote_state.network.outputs.vpc_ids : key => {
      id   = id
      cidr = data.terraform_remote_state.network.outputs.vpc_cidrs[key]
    }
  }

  wireguard_vpcs = {
    for key, vpc in local.vpcs : key => vpc
    if contains(["card", "securities"], key)
  }
}
