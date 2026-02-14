#!/bin/sh
set -eu

# 공통 상수(모든 Sentinel에서 동일)
MASTER_NAME="mymaster"
MASTER_HOST="host.containers.internal"
MASTER_PORT="6379"
QUORUM="2"

cat > /data/sentinel.conf <<CONFIG
bind 0.0.0.0
port 26379
protected-mode no
dir /data
sentinel resolve-hostnames yes
sentinel announce-hostnames yes

sentinel monitor ${MASTER_NAME} ${MASTER_HOST} ${MASTER_PORT} ${QUORUM}
sentinel down-after-milliseconds ${MASTER_NAME} 5000
sentinel failover-timeout ${MASTER_NAME} 60000
sentinel parallel-syncs ${MASTER_NAME} 1
CONFIG

exec redis-sentinel /data/sentinel.conf