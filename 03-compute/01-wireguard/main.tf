locals {
  wireguard_instances = {
    card-wireguard-01 = {
      vpc_key    = "card"
      subnet_key = "card-wireguard-public-subnet-01"
      private_ip = "10.11.51.61"
    }
    card-wireguard-02 = {
      vpc_key    = "card"
      subnet_key = "card-wireguard-public-subnet-02"
      private_ip = "10.11.52.62"
    }
    securities-wireguard-01 = {
      vpc_key    = "securities"
      subnet_key = "securities-wireguard-public-subnet-01"
      private_ip = "10.21.51.61"
    }
    securities-wireguard-02 = {
      vpc_key    = "securities"
      subnet_key = "securities-wireguard-public-subnet-02"
      private_ip = "10.21.52.62"
    }
  }
}

resource "aws_network_interface" "wireguard" {
  for_each = local.wireguard_instances

  subnet_id         = data.terraform_remote_state.network.outputs.subnet_ids[each.value.subnet_key]
  private_ips       = [each.value.private_ip]
  security_groups   = [data.terraform_remote_state.security.outputs.wg_security_group_ids[each.value.vpc_key]]
  source_dest_check = false

  tags = merge(var.default_tags, {
    Name = "${each.key}-eni"
    Role = "wireguard"
    Vpc  = each.value.vpc_key
  })
}

resource "aws_instance" "wireguard" {
  for_each = local.wireguard_instances

  ami                  = var.wireguard_ami_id
  instance_type        = var.wireguard_instance_type
  key_name             = data.terraform_remote_state.network.outputs.boce_key_pair_name
  iam_instance_profile = aws_iam_instance_profile.wg_ha.name

  primary_network_interface {
    network_interface_id = aws_network_interface.wireguard[each.key].id
  }

  root_block_device {
    volume_type = "gp3"
    volume_size = 10
  }

  tags = merge(var.default_tags, {
    Name = each.key
    Role = "wireguard"
    Vpc  = each.value.vpc_key
  })
}

resource "aws_eip" "wireguard" {
  for_each = local.wireguard_instances

  domain            = "vpc"
  network_interface = aws_network_interface.wireguard[each.key].id

  tags = merge(var.default_tags, {
    Name = "${each.key}-eip"
    Role = "wireguard"
    Vpc  = each.value.vpc_key
  })
}
