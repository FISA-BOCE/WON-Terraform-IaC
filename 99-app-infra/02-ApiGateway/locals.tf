locals {
  backend_routes = {
    cards = {
      path_part     = "cards"
      vpc_link_key  = "card"
      backend_path  = "api/cards"
      nlb_dns_name  = data.terraform_remote_state.loadbalancer.outputs.dmz_nlb_dns_names["card"]
      vpc_link_name = "card-vpc-link"
      nlb_arn       = data.terraform_remote_state.loadbalancer.outputs.dmz_nlb_arns["card"]
    }

    invest = {
      path_part     = "invest"
      vpc_link_key  = "securities"
      backend_path  = "api/invest"
      nlb_dns_name  = data.terraform_remote_state.loadbalancer.outputs.dmz_nlb_dns_names["securities"]
      vpc_link_name = "securities-vpc-link"
      nlb_arn       = data.terraform_remote_state.loadbalancer.outputs.dmz_nlb_arns["securities"]
    }
  }
}
