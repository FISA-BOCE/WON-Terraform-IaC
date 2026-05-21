resource "aws_elasticache_subnet_group" "redis_data" {
  name        = "${var.project}-${var.env}-redis-data-subnet-group"
  description = "Redis subnet group using private data subnets"
  subnet_ids  = var.data_subnet_ids

  tags = {
    Name    = "${var.project}-${var.env}-redis-data-subnet-group"
    Project = var.project
    Env     = var.env
    Layer   = "data"
  }
}

resource "aws_elasticache_replication_group" "redis" {
  replication_group_id = "${var.project}-${var.env}-redis"
  description          = "Redis replication group for cache, distributed lock, rate limit, and token blacklist"

  engine         = "redis"                # redis 생성
  engine_version = "7.1"
  node_type      = var.redis_node_type
  port           = 6379

  subnet_group_name  = aws_elasticache_subnet_group.redis_data.name   # redis 가 사용할 Subnet 후보
	security_group_ids = [aws_security_group.redis.id]                  # redis 전용 Security Group

  num_cache_clusters         = 2      # redis 노드 2개
  automatic_failover_enabled = true   # 장애 시자동 전환 
  multi_az_enabled           = true   # multi AZ 배치

  at_rest_encryption_enabled = true
  transit_encryption_enabled = true   # 전송 중 암호화
  auth_token                 = var.redis_auth_token    # redis 접속 비밀번호

  apply_immediately = true

  tags = {
    Name    = "${var.project}-${var.env}-redis"
    Project = var.project
    Env     = var.env
    Layer   = "data"
  }
}