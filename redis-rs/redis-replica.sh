#!/bin/sh
set -e

exec redis-server \
  --bind 0.0.0.0 \
  --protected-mode no \
  --appendonly yes \
  --replicaof "${ARG_REDIS_MASTER_HOST}" "${ARG_REDIS_MASTER_PORT}" \
  --replica-announce-ip host.containers.internal \
  --replica-announce-port "${ARG_REDIS_ANNOUNCE_PORT}"
