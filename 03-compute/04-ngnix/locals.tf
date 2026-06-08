locals {
  ngnix_instances = {
    card-dmz-ngnix = {
      vpc_key    = "card"
      subnet_key = "card-dmz-private-subnet"
      private_ip = "10.11.11.11"
    }

    securities-dmz-ngnix = {
      vpc_key    = "securities"
      subnet_key = "securities-dmz-private-subnet"
      private_ip = "10.21.11.11"
    }

    common-dmz-ngnix = {
      vpc_key    = "common"
      subnet_key = "common-dmz-private-subnet"
      private_ip = "10.31.11.11"
    }
  }
}
