# =========================================================
# Redis EC2
# - ElastiCache가 아닌 EC2 기반 Self-managed Redis 구성
# - 카드망 Redis 3대 + 증권망 Redis 3대 생성
# - Public IP 미할당
# - 고정 Private IP 사용
# - 기존 Security Group 사용
#   - card       : boce-card-wg-sg
#   - securities : boce-securities-test-sg
# =========================================================

# ---------------------------------------------------------
# VPC 조회
# redis_networks:
# - card
# - securities
# ---------------------------------------------------------

data "aws_vpc" "redis_networks" {
  for_each = var.enable_redis ? var.redis_networks : {}

  filter {
    name   = "tag:Name"
    values = [each.value.vpc_name]
  }

  filter {
    name   = "cidr-block"
    values = [each.value.vpc_cidr]
  }
}

# ---------------------------------------------------------
# Subnet 조회
# redis_nodes 기준으로 각 Redis 노드가 배치될 Subnet 조회
# ---------------------------------------------------------

data "aws_subnet" "redis_subnets" {
  for_each = var.enable_redis ? var.redis_nodes : {}

  filter {
    name   = "tag:Name"
    values = [each.value.subnet_name]
  }

  filter {
    name   = "cidr-block"
    values = [each.value.subnet_cidr]
  }

  filter {
    name = "vpc-id"
    values = [
      data.aws_vpc.redis_networks[each.value.network_key].id
    ]
  }
}

# ---------------------------------------------------------
# Redis EC2 Instance 생성
# ---------------------------------------------------------

resource "aws_instance" "redis" {
  for_each = var.enable_redis ? var.redis_nodes : {}

  ami           = var.ec2_ami_id
  instance_type = var.redis_instance_type
  key_name      = var.ec2_key_name

  subnet_id  = data.aws_subnet.redis_subnets[each.key].id
  private_ip = each.value.private_ip

  vpc_security_group_ids = [
    aws_security_group.redis[each.value.network_key].id
  ]

  associate_public_ip_address = var.ec2_associate_public_ip_address

  user_data = templatefile("${path.module}/scripts/install-redis.sh.tpl", {
    redis_password = var.redis_password
    redis_port     = var.redis_port
  })

  user_data_replace_on_change = true

  root_block_device {
    volume_size           = var.redis_root_volume_size
    volume_type           = var.redis_root_volume_type
    encrypted             = true
    delete_on_termination = true
  }

  metadata_options {
    http_tokens = "required"
  }

  tags = {
    Name    = each.value.name
    Project = var.project
    Env     = var.env
    Role    = "redis"
    Network = each.value.network_key
  }
}
