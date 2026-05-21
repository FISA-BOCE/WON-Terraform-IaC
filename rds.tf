resource "aws_db_subnet_group" "rds_data" {
  name        = "${var.project}-${var.env}-rds-data-subnet-group"
  description = "RDS DB subnet group using private data subnets"
  subnet_ids  = var.data_subnet_ids

  tags = {
    Name    = "${var.project}-${var.env}-rds-data-subnet-group"
    Project = var.project
    Env     = var.env
    Layer   = "data"
  }
}

resource "aws_db_instance" "mysql" {
  identifier = "${var.project}-${var.env}-mysql"

  engine         = "mysql"    # MYSQL RDS 생성
  engine_version = "8.0"
  instance_class = var.db_instance_class

  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.rds_data.name   # 어느 Subnet 후보에 둘지
  vpc_security_group_ids = [aws_security_group.rds_mysql.id]   # RDS에 붙일 Security Group

  multi_az            = true     # Primary/Standby 구성
  publicly_accessible = false    # 외부 인터넷 접근 차단

  backup_retention_period = 7
  backup_window           = "18:00-19:00"
  maintenance_window      = "sun:19:00-sun:20:00"

  auto_minor_version_upgrade = true
  deletion_protection        = false
  skip_final_snapshot        = true

  tags = {
    Name    = "${var.project}-${var.env}-mysql"
    Project = var.project
    Env     = var.env
    Layer   = "data"
  }
}
