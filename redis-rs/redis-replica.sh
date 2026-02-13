#!/bin/sh
set -e

exec redis-server \
  --bind 0.0.0.0 \
  --protected-mode no \
  --appendonly yes \
  --replicaof "${KJH_REDIS_MASTER_HOST}" "${KJH_REDIS_MASTER_PORT}" \
  --replica-announce-ip host.containers.internal \
  --replica-announce-port "${KJH_REDIS_ANNOUNCE_PORT}"
