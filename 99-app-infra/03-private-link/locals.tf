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
      name       = "common-dmz-privatelink-nlb"
      vpc_key    = "common"
      subnet_key = "common-dmz-private-subnet"
    }
    card = {
      name       = "card-dmz-privatelink-nlb"
      vpc_key    = "card"
      subnet_key = "card-dmz-private-subnet"
    }
    securities = {
      name       = "securities-dmz-privatelink-nlb"
      vpc_key    = "securities"
      subnet_key = "securities-dmz-private-subnet"
    }
  }

  private_link_endpoints = {
    common_to_card_eks = {
      name        = "common-dmz-privatelink-nlb-to-card-eks-cluster-private-subnet"
      service_key = "common"
      vpc_key     = "card"
      subnet_key  = "card-eks-cluster-private-subnet-01"
    }
    common_to_securities_eks = {
      name        = "common-dmz-privatelink-nlb-to-securities-eks-cluster-private-subnet"
      service_key = "common"
      vpc_key     = "securities"
      subnet_key  = "securities-eks-cluster-private-subnet-01"
    }
    card_to_common_server = {
      name        = "card-dmz-privatelink-nlb-to-common-server-private-subnet"
      service_key = "card"
      vpc_key     = "common"
      subnet_key  = "common-server-private-subnet"
    }
    securities_to_common_server = {
      name        = "securities-dmz-privatelink-nlb-to-common-server-private-subnet"
      service_key = "securities"
      vpc_key     = "common"
      subnet_key  = "common-server-private-subnet"
    }
  }

  private_link_dns_records = {
    card_to_common_was = {
      zone_vpc_key = "card"
      endpoint_key = "common_to_card_eks"
      name         = "common-was"
    }
    securities_to_common_was = {
      zone_vpc_key = "securities"
      endpoint_key = "common_to_securities_eks"
      name         = "common-was"
    }
    common_to_card_was = {
      zone_vpc_key = "common"
      endpoint_key = "card_to_common_server"
      name         = "card-was"
    }
    common_to_securities_was = {
      zone_vpc_key = "common"
      endpoint_key = "securities_to_common_server"
      name         = "securities-was"
    }
  }
}
