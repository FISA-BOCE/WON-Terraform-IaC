locals {
  security_group_rule_sources = {
    for entry in flatten([
      for sg_id in var.allowed_source_security_group_ids : [
        {
          key         = "redis-${sg_id}"
          port        = var.redis_port
          sg_id       = sg_id
          description = "Allow Redis from ${sg_id}"
        },
        {
          key         = "sentinel-${sg_id}"
          port        = var.sentinel_port
          sg_id       = sg_id
          description = "Allow Redis Sentinel from ${sg_id}"
        }
      ]
    ]) : entry.key => entry
  }

  ssh_sg_rules = {
    for sg_id in var.ssh_allowed_security_group_ids : sg_id => sg_id
  }

  ssh_cidr_rules = {
    for cidr in var.ssh_allowed_cidrs : replace(replace(cidr, "/", "-"), ".", "-") => cidr
  }
}

resource "aws_security_group" "this" {
  name        = "${var.project}-${var.env}-${var.network_key}-redis-sentinel-sg"
  description = "Redis Sentinel HA security group for ${var.network_key}"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name    = "${var.project}-${var.env}-${var.network_key}-redis-sentinel-sg"
    Project = var.project
    Env     = var.env
    Network = var.network_key
    Layer   = "data"
    Service = "redis-sentinel-ha"
  })
}

resource "aws_vpc_security_group_ingress_rule" "redis_and_sentinel_from_sources" {
  for_each = local.security_group_rule_sources

  security_group_id            = aws_security_group.this.id
  referenced_security_group_id = each.value.sg_id

  ip_protocol = "tcp"
  from_port   = each.value.port
  to_port     = each.value.port

  description = each.value.description
}

resource "aws_vpc_security_group_ingress_rule" "redis_from_self" {
  security_group_id            = aws_security_group.this.id
  referenced_security_group_id = aws_security_group.this.id

  ip_protocol = "tcp"
  from_port   = var.redis_port
  to_port     = var.redis_port

  description = "Allow Redis replication traffic within the Redis security group"
}

resource "aws_vpc_security_group_ingress_rule" "sentinel_from_self" {
  security_group_id            = aws_security_group.this.id
  referenced_security_group_id = aws_security_group.this.id

  ip_protocol = "tcp"
  from_port   = var.sentinel_port
  to_port     = var.sentinel_port

  description = "Allow Redis Sentinel traffic within the Redis security group"
}

resource "aws_vpc_security_group_ingress_rule" "ssh_from_cidrs" {
  for_each = local.ssh_cidr_rules

  security_group_id = aws_security_group.this.id

  ip_protocol = "tcp"
  from_port   = 22
  to_port     = 22
  cidr_ipv4   = each.value

  description = "Allow SSH from managed network ${each.value}"
}

resource "aws_vpc_security_group_ingress_rule" "ssh_from_security_groups" {
  for_each = local.ssh_sg_rules

  security_group_id            = aws_security_group.this.id
  referenced_security_group_id = each.value

  ip_protocol = "tcp"
  from_port   = 22
  to_port     = 22

  description = "Allow SSH from managed security group ${each.value}"
}

resource "aws_vpc_security_group_egress_rule" "all_egress" {
  security_group_id = aws_security_group.this.id

  ip_protocol = "-1"
  cidr_ipv4   = "0.0.0.0/0"

  description = "Default outbound traffic"
}

resource "aws_instance" "this" {
  for_each = var.nodes

  ami                         = var.ami_id
  instance_type               = var.instance_type
  key_name                    = var.key_name
  subnet_id                   = each.value.subnet_id
  private_ip                  = each.value.private_ip
  associate_public_ip_address = var.associate_public_ip_address
  vpc_security_group_ids      = [aws_security_group.this.id]

  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = var.root_volume_type
    encrypted             = true
    delete_on_termination = true
  }

  metadata_options {
    http_tokens = "required"
  }

  tags = merge(var.tags, {
    Name    = each.value.name
    Project = var.project
    Env     = var.env
    Network = var.network_key
    Role    = each.value.is_master ? "redis-master" : "redis-replica"
    Service = "redis-sentinel-ha"
  })
}
