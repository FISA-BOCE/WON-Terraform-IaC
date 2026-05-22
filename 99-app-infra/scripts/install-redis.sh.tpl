#!/bin/bash
set -euxo pipefail

# =========================================================
# Install Redis on Ubuntu 24.04
# - EC2 기반 Self-managed Redis 구성
# - Terraform templatefile()에서 redis_password, redis_port 주입
# =========================================================

apt-get update -y
DEBIAN_FRONTEND=noninteractive apt-get install -y redis-server redis-tools

cp /etc/redis/redis.conf /etc/redis/redis.conf.bak

# 외부 접속 허용: Security Group으로 접근 제어
sed -i -E "s/^bind .*/bind 0.0.0.0/" /etc/redis/redis.conf

# Redis 포트 설정
sed -i -E "s/^port .*/port ${redis_port}/" /etc/redis/redis.conf

# systemd 관리 설정
sed -i -E "s/^supervised .*/supervised systemd/" /etc/redis/redis.conf

# appendonly 활성화
sed -i -E "s/^appendonly .*/appendonly yes/" /etc/redis/redis.conf

# 비밀번호 설정
if grep -q "^# requirepass" /etc/redis/redis.conf; then
  sed -i -E "s/^# requirepass .*/requirepass ${redis_password}/" /etc/redis/redis.conf
else
  echo "requirepass ${redis_password}" >> /etc/redis/redis.conf
fi

systemctl enable redis-server
systemctl restart redis-server

# 기동 확인
redis-cli -p ${redis_port} -a "${redis_password}" ping