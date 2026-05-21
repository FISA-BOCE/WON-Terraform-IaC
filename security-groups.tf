resource "aws_security_group" "rds_mysql" {
  name        = "${var.project}-${var.env}-rds-mysql-sg"
  description = "Allow MySQL access from EKS WAS only"
  vpc_id      = var.vpc_id

  tags = {
    Name    = "${var.project}-${var.env}-rds-mysql-sg"
    Project = var.project
    Env     = var.env
    Layer   = "data"
  }
}

resource "aws_security_group" "redis" {
  name        = "${var.project}-${var.env}-redis-sg"
  description = "Allow Redis access from EKS WAS only"
  vpc_id      = var.vpc_id

  tags = {
    Name    = "${var.project}-${var.env}-redis-sg"
    Project = var.project
    Env     = var.env
    Layer   = "data"
  }
}

resource "aws_vpc_security_group_ingress_rule" "rds_mysql_from_eks" {
  security_group_id            = aws_security_group.rds_mysql.id
  referenced_security_group_id = var.eks_app_security_group_id

  ip_protocol = "tcp"
  from_port   = 3306
  to_port     = 3306

  description = "Allow MySQL from EKS WAS"
}

resource "aws_vpc_security_group_ingress_rule" "redis_from_eks" {
  security_group_id            = aws_security_group.redis.id
  referenced_security_group_id = var.eks_app_security_group_id

  ip_protocol = "tcp"
  from_port   = 6379
  to_port     = 6379

  description = "Allow Redis from EKS WAS"
}

resource "aws_vpc_security_group_egress_rule" "rds_all_egress" {
  security_group_id = aws_security_group.rds_mysql.id

  ip_protocol = "-1"
  cidr_ipv4   = "0.0.0.0/0"

  description = "Default outbound traffic"
}

resource "aws_vpc_security_group_egress_rule" "redis_all_egress" {
  security_group_id = aws_security_group.redis.id

  ip_protocol = "-1"
  cidr_ipv4   = "0.0.0.0/0"

  description = "Default outbound traffic"
}