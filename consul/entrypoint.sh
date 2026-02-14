#!/bin/sh
set -e

# retry-join 인수 구성
RETRY_JOIN_ARGS=""
for server in $ARG_CONSUL_RETRY_JOIN; do
  RETRY_JOIN_ARGS="$RETRY_JOIN_ARGS -retry-join=$server"
done

# 서버 모드로 실행
exec consul agent \
  -server \
  -bootstrap-expect=3 \
  -data-dir=/consul/data \
  -client=0.0.0.0 \
  $RETRY_JOIN_ARGS
