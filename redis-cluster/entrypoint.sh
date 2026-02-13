#!/bin/sh
set -e

exec redis-server \
  --bind 0.0.0.0 \
  --protected-mode no \
  --appendonly yes \
  --cluster-enabled yes \
  --cluster-config-file /data/nodes.conf \
  --cluster-node-timeout 5000 \
  --cluster-announce-ip host.containers.internal \
  --cluster-announce-port "${KJH_REDIS_CLUSTER_PORT}" \
  --cluster-announce-bus-port "${KJH_REDIS_CLUSTER_BUS_PORT}"
