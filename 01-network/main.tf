data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  vpcs = {
    card = {
      name = "card-vpc"
      cidr = "10.11.0.0/16"
    }
    securities = {
      name = "securities-vpc"
      cidr = "10.21.0.0/16"
    }
    common = {
      name = "common-vpc"
      cidr = "10.31.0.0/16"
    }
  }

  subnets = {
    card-dmz-private-subnet = {
      vpc_key = "card"
      cidr    = "10.11.11.0/24"
      az_idx  = 0
      public  = false
    }
    card-eks-cluster-private-subnet-01 = {
      vpc_key = "card"
      cidr    = "10.11.21.0/24"
      az_idx  = 0
      public  = false
    }
    card-eks-cluster-private-subnet-02 = {
      vpc_key = "card"
      cidr    = "10.11.22.0/24"
      az_idx  = 1
      public  = false
    }
    card-data-layer-private-subnet-01 = {
      vpc_key = "card"
      cidr    = "10.11.31.0/24"
      az_idx  = 0
      public  = false
    }
    card-data-layer-private-subnet-02 = {
      vpc_key = "card"
      cidr    = "10.11.32.0/24"
      az_idx  = 1
      public  = false
    }
    card-ai-db-private-subnet = {
      vpc_key = "card"
      cidr    = "10.11.41.0/24"
      az_idx  = 0
      public  = false
    }
    card-wireguard-public-subnet-01 = {
      vpc_key = "card"
      cidr    = "10.11.51.0/24"
      az_idx  = 0
      public  = true
    }
    card-wireguard-public-subnet-02 = {
      vpc_key = "card"
      cidr    = "10.11.52.0/24"
      az_idx  = 1
      public  = true
    }
    securities-dmz-private-subnet = {
      vpc_key = "securities"
      cidr    = "10.21.11.0/24"
      az_idx  = 0
      public  = false
    }
    securities-eks-cluster-private-subnet-01 = {
      vpc_key = "securities"
      cidr    = "10.21.21.0/24"
      az_idx  = 0
      public  = false
    }
    securities-eks-cluster-private-subnet-02 = {
      vpc_key = "securities"
      cidr    = "10.21.22.0/24"
      az_idx  = 1
      public  = false
    }
    securities-data-layer-private-subnet-01 = {
      vpc_key = "securities"
      cidr    = "10.21.31.0/24"
      az_idx  = 0
      public  = false
    }
    securities-data-layer-private-subnet-02 = {
      vpc_key = "securities"
      cidr    = "10.21.32.0/24"
      az_idx  = 1
      public  = false
    }
    securities-ai-db-private-subnet = {
      vpc_key = "securities"
      cidr    = "10.21.41.0/24"
      az_idx  = 0
      public  = false
    }
    securities-wireguard-public-subnet-01 = {
      vpc_key = "securities"
      cidr    = "10.21.51.0/24"
      az_idx  = 0
      public  = true
    }
    securities-wireguard-public-subnet-02 = {
      vpc_key = "securities"
      cidr    = "10.21.52.0/24"
      az_idx  = 1
      public  = true
    }
    common-dmz-private-subnet = {
      vpc_key = "common"
      cidr    = "10.31.11.0/24"
      az_idx  = 0
      public  = false
    }
    common-server-private-subnet = {
      vpc_key = "common"
      cidr    = "10.31.21.0/24"
      az_idx  = 0
      public  = false
    }
    common-bastion-public-subnet = {
      vpc_key = "common"
      cidr    = "10.31.51.0/24"
      az_idx  = 0
      public  = true
    }
  }

  public_vpcs = {
    for key, vpc in local.vpcs : key => vpc
    if length([
      for subnet in local.subnets : subnet
      if subnet.vpc_key == key && subnet.public
    ]) > 0
  }

  public_subnets = {
    for key, subnet in local.subnets : key => subnet
    if subnet.public
  }
}

resource "aws_vpc" "this" {
  for_each = local.vpcs

  cidr_block           = each.value.cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.default_tags, {
    Name = each.value.name
  })
}

resource "aws_default_security_group" "this" {
  for_each = aws_vpc.this
  vpc_id   = each.value.id
  ingress  = []
  egress   = []
  tags = merge(var.default_tags, {
    Name = "${local.vpcs[each.key].name}-default-sg"
  })
}

resource "aws_subnet" "this" {
  for_each = local.subnets

  vpc_id                  = aws_vpc.this[each.value.vpc_key].id
  cidr_block              = each.value.cidr
  availability_zone       = data.aws_availability_zones.available.names[each.value.az_idx]
  map_public_ip_on_launch = each.value.public

  tags = merge(var.default_tags, {
    Name = each.key
    Tier = each.value.public ? "public" : "private"
  })
}

resource "aws_internet_gateway" "this" {
  for_each = local.public_vpcs

  vpc_id = aws_vpc.this[each.key].id

  tags = merge(var.default_tags, {
    Name = "${each.value.name}-igw"
  })
}

resource "aws_route_table" "public" {
  for_each = local.public_vpcs

  vpc_id = aws_vpc.this[each.key].id

  tags = merge(var.default_tags, {
    Name = "${each.value.name}-public-rt"
  })
}

resource "aws_route" "public_default" {
  for_each = local.public_vpcs

  route_table_id         = aws_route_table.public[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this[each.key].id
}

resource "aws_route_table_association" "public" {
  for_each = local.public_subnets

  subnet_id      = aws_subnet.this[each.key].id
  route_table_id = aws_route_table.public[each.value.vpc_key].id
}
