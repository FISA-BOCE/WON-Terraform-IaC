resource "aws_instance" "ngnix" {
  for_each = local.ngnix_instances

  ami                         = var.ngnix_ami_id
  instance_type               = var.ngnix_instance_type
  key_name                    = data.terraform_remote_state.network.outputs.boce_key_pair_name
  subnet_id                   = data.terraform_remote_state.network.outputs.subnet_ids[each.value.subnet_key]
  private_ip                  = each.value.private_ip
  associate_public_ip_address = false
  vpc_security_group_ids      = [data.terraform_remote_state.security.outputs.nginx_security_group_ids[each.value.vpc_key]]

  root_block_device {
    volume_type = "gp3"
    volume_size = var.ngnix_root_volume_size
  }

  metadata_options {
    http_tokens = "required"
  }

  tags = merge(var.default_tags, {
    Name = each.key
    Role = "ngnix"
    Vpc  = each.value.vpc_key
  })
}
