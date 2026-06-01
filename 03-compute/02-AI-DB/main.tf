locals {
  ai_db_instances = {
    card-ai-mysql-db = {
      vpc_key    = "card"
      subnet_key = "card-ai-db-private-subnet"
      private_ip = "10.11.41.81"
      db_type    = "mysql"
    }
    card-ai-graph-db = {
      vpc_key    = "card"
      subnet_key = "card-ai-db-private-subnet"
      private_ip = "10.11.41.82"
      db_type    = "graph"
    }
    securities-ai-mysql-db = {
      vpc_key    = "securities"
      subnet_key = "securities-ai-db-private-subnet"
      private_ip = "10.21.41.81"
      db_type    = "mysql"
    }
    securities-ai-graph-db = {
      vpc_key    = "securities"
      subnet_key = "securities-ai-db-private-subnet"
      private_ip = "10.21.41.82"
      db_type    = "graph"
    }
  }
}

resource "aws_instance" "ai_db" {
  for_each = local.ai_db_instances

  ami                         = var.ai_db_ami_id
  instance_type               = var.ai_db_instance_type
  key_name                    = data.terraform_remote_state.network.outputs.boce_key_pair_name
  subnet_id                   = data.terraform_remote_state.network.outputs.subnet_ids[each.value.subnet_key]
  private_ip                  = each.value.private_ip
  vpc_security_group_ids      = [data.terraform_remote_state.security.outputs.ai_db_security_group_ids[each.value.vpc_key]]
  associate_public_ip_address = false

  root_block_device {
    volume_type = "gp3"
    volume_size = 50
  }

  tags = merge(var.default_tags, {
    Name = each.key
    Role = "ai-db"
    Type = each.value.db_type
    Vpc  = each.value.vpc_key
  })
}
