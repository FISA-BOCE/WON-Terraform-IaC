locals {
  ansible_bastion_instances = {
    common-ansible-bastion-server = {
      vpc_key    = "common"
      subnet_key = "common-bastion-public-subnet"
      private_ip = "10.31.51.100"
    }
    securities-ansible-bastion-server = {
      vpc_key    = "securities"
      subnet_key = "securities-wireguard-public-subnet-01"
      private_ip = "10.21.51.100"
    }
    card-ansible-bastion-server = {
      vpc_key    = "card"
      subnet_key = "card-wireguard-public-subnet-01"
      private_ip = "10.11.51.100"
    }
  }
}

resource "aws_instance" "ansible_bastion" {
  for_each = local.ansible_bastion_instances

  ami                         = var.ansible_bastion_ami_id
  instance_type               = var.ansible_bastion_instance_type
  key_name                    = data.terraform_remote_state.network.outputs.boce_key_pair_name
  subnet_id                   = data.terraform_remote_state.network.outputs.subnet_ids[each.value.subnet_key]
  private_ip                  = each.value.private_ip
  associate_public_ip_address = true
  vpc_security_group_ids      = [data.terraform_remote_state.security.outputs.ansible_bastion_server_security_group_ids[each.value.vpc_key]]

  root_block_device {
    volume_type = "gp3"
    volume_size = 10
  }

  tags = merge(var.default_tags, {
    Name = each.key
    Role = "ansible-bastion"
    Vpc  = each.value.vpc_key
  })
}
