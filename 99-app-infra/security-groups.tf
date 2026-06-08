# =========================================================
# Application Security Groups
# - RDS/Redis 접근 주체가 되는 App/WAS/EKS용 SG
# =========================================================

resource "aws_security_group" "app" {
  for_each = local.rds_networks

  name        = "${var.project}-${var.env}-${each.key}-app-sg"
  description = "Application security group for ${each.key} network"
  vpc_id      = each.value.vpc_id

  tags = {
    Name    = "${var.project}-${var.env}-${each.key}-app-sg"
    Project = var.project
    Env     = var.env
    Network = each.key
    Layer   = "app"
  }
}


# =========================================================
# RDS Security Groups
# - 카드망/증권망 각각 RDS MySQL Security Group 생성
# - Redis는 기존 Security Group을 조회해서 사용하므로 여기서 생성하지 않음
# =========================================================

resource "aws_security_group" "rds_mysql" {
  for_each = local.rds_networks

  name        = "${var.project}-${var.env}-${each.key}-rds-mysql-sg"
  description = "Allow MySQL access from ${each.key} app only"
  vpc_id      = each.value.vpc_id

  tags = {
    Name    = "${var.project}-${var.env}-${each.key}-rds-mysql-sg"
    Project = var.project
    Env     = var.env
    Network = each.key
    Layer   = "data"
  }
}

resource "aws_vpc_security_group_ingress_rule" "rds_mysql_from_app" {
  for_each = local.rds_networks

  security_group_id            = aws_security_group.rds_mysql[each.key].id
  referenced_security_group_id = aws_security_group.app[each.key].id

  ip_protocol = "tcp"
  from_port   = 3306
  to_port     = 3306

  description = "Allow MySQL from ${each.key} app"
}

resource "aws_vpc_security_group_ingress_rule" "rds_mysql_from_eks" {
  for_each = local.rds_networks

  security_group_id            = aws_security_group.rds_mysql[each.key].id
  referenced_security_group_id = data.terraform_remote_state.eks.outputs.eks_cluster_security_group_ids[each.key]

  ip_protocol = "tcp"
  from_port   = 3306
  to_port     = 3306

  description = "Allow MySQL from ${each.key} EKS"
}

resource "aws_vpc_security_group_egress_rule" "rds_all_egress" {
  for_each = local.rds_networks

  security_group_id = aws_security_group.rds_mysql[each.key].id

  ip_protocol = "-1"
  cidr_ipv4   = "0.0.0.0/0"

  description = "Default outbound traffic"
}


# =========================================================
# Redis Security Groups
# =========================================================

resource "aws_security_group" "redis" {
  for_each = var.enable_redis ? local.rds_networks : {}

  name        = "${var.project}-${var.env}-${each.key}-redis-sg"
  description = "Allow Redis access from ${each.key} app only"
  vpc_id      = each.value.vpc_id

  tags = {
    Name    = "${var.project}-${var.env}-${each.key}-redis-sg"
    Project = var.project
    Env     = var.env
    Network = each.key
    Layer   = "data"
  }
}

resource "aws_vpc_security_group_ingress_rule" "redis_from_app" {
  for_each = var.enable_redis ? local.rds_networks : {}

  security_group_id            = aws_security_group.redis[each.key].id
  referenced_security_group_id = aws_security_group.app[each.key].id

  ip_protocol = "tcp"
  from_port   = 6379
  to_port     = 6379

  description = "Allow Redis from ${each.key} app"
}

resource "aws_vpc_security_group_egress_rule" "redis_all_egress" {
  for_each = var.enable_redis ? local.rds_networks : {}

  security_group_id = aws_security_group.redis[each.key].id

  ip_protocol = "-1"
  cidr_ipv4   = "0.0.0.0/0"

  description = "Default outbound traffic"
}
