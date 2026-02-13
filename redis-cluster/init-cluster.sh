#!/bin/sh
set -e

echo "[Redis Cluster Init] Starting initialization..."

# Wait for all 6 Redis nodes to be ready
echo "[Redis Cluster Init] Waiting for Redis nodes to be ready..."
until redis-cli -h host.containers.internal -p 6379 ping >/dev/null 2>&1; do sleep 2; done
echo "[Redis Cluster Init] Node 1 (6379) is ready"
until redis-cli -h host.containers.internal -p 6380 ping >/dev/null 2>&1; do sleep 2; done
echo "[Redis Cluster Init] Node 2 (6380) is ready"
until redis-cli -h host.containers.internal -p 6381 ping >/dev/null 2>&1; do sleep 2; done
echo "[Redis Cluster Init] Node 3 (6381) is ready"
until redis-cli -h host.containers.internal -p 6382 ping >/dev/null 2>&1; do sleep 2; done
echo "[Redis Cluster Init] Node 4 (6382) is ready"
until redis-cli -h host.containers.internal -p 6383 ping >/dev/null 2>&1; do sleep 2; done
echo "[Redis Cluster Init] Node 5 (6383) is ready"
until redis-cli -h host.containers.internal -p 6384 ping >/dev/null 2>&1; do sleep 2; done
echo "[Redis Cluster Init] Node 6 (6384) is ready"

# Check if cluster is already initialized
echo "[Redis Cluster Init] Checking if cluster is already initialized..."
if redis-cli --cluster check host.containers.internal:6379 >/dev/null 2>&1; then
  echo "[Redis Cluster Init] Cluster is already initialized. Skipping."
  exit 0
fi

# Create the cluster with 3 masters and 3 replicas
echo "[Redis Cluster Init] Creating cluster with 3 masters and 3 replicas..."
echo yes | redis-cli --cluster create \
  host.containers.internal:6379 host.containers.internal:6380 host.containers.internal:6381 \
  host.containers.internal:6382 host.containers.internal:6383 host.containers.internal:6384 \
  --cluster-replicas 1

echo "[Redis Cluster Init] Cluster initialization completed successfully!"
