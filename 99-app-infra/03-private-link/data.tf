data "aws_caller_identity" "current" {}

data "terraform_remote_state" "network" {
  backend = "local"

  config = {
    path = var.network_state_path
  }
}

data "terraform_remote_state" "loadbalancer" {
  backend = "local"

  config = {
    path = var.loadbalancer_state_path
  }
}

data "aws_subnet" "service" {
  for_each = local.endpoint_services

  id = data.terraform_remote_state.network.outputs.subnet_ids[each.value.subnet_key]
}

data "aws_subnet" "endpoint" {
  for_each = local.private_link_endpoints

  id = data.terraform_remote_state.network.outputs.subnet_ids[each.value.subnet_key]
}
