#!/bin/bash
set -e

echo "[Mongo Cluster Init] Starting router initialization..."

# Wait for mongos to be ready
echo "[Mongo Cluster Init] Waiting for mongos to be ready..."
until mongosh --host mongos-1 --port 27017 --quiet --eval "db.adminCommand({ ping: 1 }).ok"; do
  sleep 2
done
echo "[Mongo Cluster Init] Mongos is ready"

# Verify mongos can see config servers
until mongosh --host mongos-1 --port 27017 --quiet --eval "db.adminCommand({ listShards: 1 }).ok"; do
  echo "[Mongo Cluster Init] Mongos not fully ready, waiting..."
  sleep 2
done
echo "[Mongo Cluster Init] Mongos fully connected to cluster"

# Wait for mongos shard registry to stabilize
# (On restart, mongos has ReadThroughCacheTimeMonotonicityViolation transiently
#  and listShards may return empty even if shards are registered in config server.
#  Wait until listShards returns a consistent result across 3 consecutive checks.)
echo "[Mongo Cluster Init] Waiting for shard registry to stabilize..."
prev_count=""
stable=0
while [ "$stable" -lt 3 ]; do
  count=$(mongosh --host mongos-1 --port 27017 --quiet --eval "
    print(db.adminCommand({ listShards: 1 }).shards.length)
  " 2>/dev/null | tail -1 || echo "0")
  if [ "$count" = "$prev_count" ]; then
    stable=$((stable + 1))
  else
    stable=0
    prev_count="$count"
  fi
  sleep 2
done
echo "[Mongo Cluster Init] Shard registry stable (${prev_count} shards registered)"

# Function to add shard with retry (skips if already registered)
add_shard_with_retry() {
  local shard_name=$1
  local shard_conn=$2
  local max_retries=10
  local retry=0

  echo "[Mongo Cluster Init] Adding ${shard_name}..."
  already=$(mongosh --host mongos-1 --port 27017 --quiet --eval "
    print(db.adminCommand({ listShards: 1 }).shards.some(s => s._id === '${shard_name}') ? 'SHARD_EXISTS' : 'SHARD_MISSING')
  " 2>/dev/null | grep -c 'SHARD_EXISTS' || true)
  if [ "${already:-0}" -ge 1 ]; then
    echo "[Mongo Cluster Init] ${shard_name} already registered. Skipping."
    return 0
  fi

  while [ $retry -lt $max_retries ]; do
    result=$(timeout 30 mongosh --host mongos-1 --port 27017 --quiet --eval "
      const result = sh.addShard('${shard_conn}');
      if (!result.ok) { throw new Error(JSON.stringify(result)); }
      print(JSON.stringify(result));
    " 2>&1)
    exit_code=$?
    if [ $exit_code -eq 0 ]; then
      break
    fi
    retry=$((retry + 1))
    echo "[Mongo Cluster Init] Retry ${retry}/${max_retries} for ${shard_name} (exit=${exit_code}): ${result}"
    sleep 5
  done

  if [ $retry -ge $max_retries ]; then
    echo "[Mongo Cluster Init] ERROR: Failed to add ${shard_name} after ${max_retries} retries"
    exit 1
  fi
  echo "[Mongo Cluster Init] ${shard_name} added successfully"
}

add_shard_with_retry "shard1RS" "shard1RS/mongo-shard1-1:27018,mongo-shard1-2:27018,mongo-shard1-3:27018"
add_shard_with_retry "shard2RS" "shard2RS/mongo-shard2-1:27018,mongo-shard2-2:27018,mongo-shard2-3:27018"
add_shard_with_retry "shard3RS" "shard3RS/mongo-shard3-1:27018,mongo-shard3-2:27018,mongo-shard3-3:27018"

# Verify all shards are registered
echo "[Mongo Cluster Init] Verifying shards..."
mongosh --host mongos-1 --port 27017 --quiet --eval "
  const shards = db.adminCommand({ listShards: 1 });
  print('[Mongo Cluster Init] Registered shards: ' + shards.shards.length);
  shards.shards.forEach(s => print('  - ' + s._id + ': ' + s.host));
  if (shards.shards.length < 3) {
    print('[Mongo Cluster Init] ERROR: Expected 3 shards, found ' + shards.shards.length);
    quit(1);
  }
"

echo "[Mongo Cluster Init] Router initialization completed!"
