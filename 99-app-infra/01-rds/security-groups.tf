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
  for_each = local.rds_networks_with_eks

  security_group_id            = aws_security_group.rds_mysql[each.key].id
  referenced_security_group_id = local.eks_cluster_security_group_ids[each.key]

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
