locals {
  dmz_nlbs = {
    card = {
      name          = "card-dmz-nlb"
      subnet_key    = "card-dmz-private-subnet"
      instance_name = "card-dmz-ngnix"
    }

    securities = {
      name          = "securities-dmz-nlb"
      subnet_key    = "securities-dmz-private-subnet"
      instance_name = "securities-dmz-ngnix"
    }

    common = {
      name          = "common-dmz-nlb"
      subnet_key    = "common-dmz-private-subnet"
      instance_name = "common-dmz-ngnix"
    }
  }
}
