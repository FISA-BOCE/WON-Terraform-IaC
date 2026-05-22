# =========================================================
# RDS MySQL
# - 카드망/증권망 각각 RDS MySQL 생성
# - card-vpc       : card RDS
# - securities-vpc : securities RDS
# =========================================================

resource "aws_db_subnet_group" "rds_data" {
  for_each = var.rds_networks

  name        = "${var.project}-${var.env}-${each.key}-rds-data-subnet-group"
  description = "RDS DB subnet group for ${each.key} private data subnets"
  subnet_ids  = each.value.data_subnet_ids

  tags = {
    Name    = "${var.project}-${var.env}-${each.key}-rds-data-subnet-group"
    Project = var.project
    Env     = var.env
    Network = each.key
    Layer   = "data"
  }
}

resource "aws_db_instance" "mysql" {
  for_each = var.rds_networks

  identifier = "${var.project}-${var.env}-${each.key}-mysql"

  engine         = "mysql"
  engine_version = "8.0"
  instance_class = var.db_instance_class

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name  = each.value.db_name
  username = each.value.db_username
  password = var.db_passwords[each.key]

  db_subnet_group_name = aws_db_subnet_group.rds_data[each.key].name

  vpc_security_group_ids = [
    aws_security_group.rds_mysql[each.key].id
  ]

  multi_az            = var.rds_multi_az
  publicly_accessible = false

  backup_retention_period = 7
  backup_window           = "18:00-19:00"
  maintenance_window      = "sun:19:00-sun:20:00"

  auto_minor_version_upgrade = true
  deletion_protection        = false
  skip_final_snapshot        = true

  tags = {
    Name    = "${var.project}-${var.env}-${each.key}-mysql"
    Project = var.project
    Env     = var.env
    Network = each.key
    Layer   = "data"
  }
}