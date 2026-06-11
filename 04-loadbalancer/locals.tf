locals {
  dmz_nlbs = {
    card = {
      name          = "card-dmz-privatelink-nlb"
      subnet_key    = "card-dmz-private-subnet"
      instance_name = "card-dmz-ngnix"
    }

    securities = {
      name          = "securities-dmz-privatelink-nlb"
      subnet_key    = "securities-dmz-private-subnet"
      instance_name = "securities-dmz-ngnix"
    }

    common = {
      name          = "common-dmz-privatelink-nlb"
      subnet_key    = "common-dmz-private-subnet"
      instance_name = "common-dmz-ngnix"
    }
  }

  apigateway_nlbs = {
    for key, nlb in local.dmz_nlbs : key => merge(nlb, {
      name = "${key}-dmz-apigateway-nlb"
    })
    if contains(["card", "securities"], key)
  }
}
