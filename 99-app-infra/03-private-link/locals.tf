locals {
  vpcs = {
    card = {
      name = "card-vpc"
    }
    securities = {
      name = "securities-vpc"
    }
    common = {
      name = "common-vpc"
    }
  }

  endpoint_services = {
    common = {
      name       = "common-dmz-nlb"
      vpc_key    = "common"
      subnet_key = "common-dmz-private-subnet"
    }
    card = {
      name       = "card-dmz-nlb"
      vpc_key    = "card"
      subnet_key = "card-dmz-private-subnet"
    }
    securities = {
      name       = "securities-dmz-nlb"
      vpc_key    = "securities"
      subnet_key = "securities-dmz-private-subnet"
    }
  }

  private_link_endpoints = {
    common_to_card_eks = {
      name        = "common-dmz-nlb-to-card-eks-cluster-private-subnet"
      service_key = "common"
      vpc_key     = "card"
      subnet_key  = "card-eks-cluster-private-subnet-01"
    }
    common_to_securities_eks = {
      name        = "common-dmz-nlb-to-securities-eks-cluster-private-subnet"
      service_key = "common"
      vpc_key     = "securities"
      subnet_key  = "securities-eks-cluster-private-subnet-01"
    }
    card_to_common_server = {
      name        = "card-dmz-nlb-to-common-server-private-subnet"
      service_key = "card"
      vpc_key     = "common"
      subnet_key  = "common-server-private-subnet"
    }
    securities_to_common_server = {
      name        = "securities-dmz-nlb-to-common-server-private-subnet"
      service_key = "securities"
      vpc_key     = "common"
      subnet_key  = "common-server-private-subnet"
    }
  }
}
