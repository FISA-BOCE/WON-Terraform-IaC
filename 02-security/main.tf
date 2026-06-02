resource "aws_security_group" "wg" {
  for_each = local.wireguard_vpcs

  name        = "${var.project_name}-${each.key}-wg-sg"
  description = "Security group for WireGuard EC2 instances"
  vpc_id      = each.value.id

  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  ingress {
    description = "ICMP from anywhere"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  ingress {
    description = "WireGuard UDP from anywhere"
    from_port   = 51820
    to_port     = 51820
    protocol    = "udp"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  tags = merge(var.default_tags, {
    Name = "${var.project_name}-${each.key}-wg-sg"
    Vpc  = each.key
  })
}

resource "aws_security_group" "test" {
  for_each = local.vpcs

  name        = "${var.project_name}-${each.key}-test-sg"
  description = "Security group for private test EC2"
  vpc_id      = each.value.id

  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  ingress {
    description = "ICMP from anywhere"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  ingress {
    description = "All traffic from VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [
      each.value.cidr
    ]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  tags = merge(var.default_tags, {
    Name = "${var.project_name}-${each.key}-test-sg"
    Vpc  = each.key
  })
}

resource "aws_security_group" "ansible_bastion_server" {
  for_each = local.ansible_bastion_vpcs

  name        = "${each.key}-ansible-bastion-server-sg"
  description = "Security group for Ansible bastion server EC2"
  vpc_id      = each.value.id

  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  tags = merge(var.default_tags, {
    Name = "${each.key}-ansible-bastion-server-sg"
    Vpc  = each.key
  })
}

resource "aws_security_group" "ai_db" {
  for_each = local.wireguard_vpcs

  name        = "${each.key}-ai-db-sg"
  description = "Security group for AI DB EC2"
  vpc_id      = each.value.id

  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  ingress {
    description = "ICMP from anywhere"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  ingress {
    description = "All traffic from VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [
      each.value.cidr
    ]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  tags = merge(var.default_tags, {
    Name = "${each.key}-ai-db-sg"
    Vpc  = each.key
  })
}
