#!/bin/bash
set -e

echo "[Mongo Router Init] Starting router initialization..."

# Wait for mongos to be ready
echo "[Mongo Router Init] Waiting for mongos to be ready..."
until mongosh --host mongos-1 --port 27017 --quiet --eval "db.adminCommand({ ping: 1 }).ok"; do
  sleep 2
done
echo "[Mongo Router Init] Mongos is ready"

# Wait for mongos to fully initialize and connect to config servers
echo "[Mongo Router Init] Waiting for mongos to connect to config servers..."
sleep 5

# Verify mongos can see config servers
until mongosh --host mongos-1 --port 27017 --quiet --eval "db.adminCommand({ listShards: 1 }).ok"; do
  echo "[Mongo Router Init] Mongos not fully ready, waiting..."
  sleep 2
done
echo "[Mongo Router Init] Mongos fully connected to cluster"

# Function to add shard with retry
add_shard_with_retry() {
  local shard_name=$1
  local shard_conn=$2
  local max_retries=10
  local retry=0

  echo "[Mongo Router Init] Adding ${shard_name}..."
  while [ $retry -lt $max_retries ]; do
    result=$(mongosh --host mongos-1 --port 27017 --quiet --eval "
      const result = sh.addShard('${shard_conn}');
      print(JSON.stringify(result));
    " 2>&1) && break
    retry=$((retry + 1))
    echo "[Mongo Router Init] Retry ${retry}/${max_retries} for ${shard_name}..."
    sleep 5
  done

  if [ $retry -ge $max_retries ]; then
    echo "[Mongo Router Init] ERROR: Failed to add ${shard_name} after ${max_retries} retries"
    exit 1
  fi
  echo "[Mongo Router Init] ${shard_name} added successfully"
}

add_shard_with_retry "shard1RS" "shard1RS/shard1-1:27018,shard1-2:27018,shard1-3:27018"
add_shard_with_retry "shard2RS" "shard2RS/shard2-1:27018,shard2-2:27018,shard2-3:27018"
add_shard_with_retry "shard3RS" "shard3RS/shard3-1:27018,shard3-2:27018,shard3-3:27018"

# Verify all shards are registered
echo "[Mongo Router Init] Verifying shards..."
mongosh --host mongos-1 --port 27017 --quiet --eval "
  const shards = db.adminCommand({ listShards: 1 });
  print('[Mongo Router Init] Registered shards: ' + shards.shards.length);
  shards.shards.forEach(s => print('  - ' + s._id + ': ' + s.host));
  if (shards.shards.length < 3) {
    print('[Mongo Router Init] ERROR: Expected 3 shards, found ' + shards.shards.length);
    quit(1);
  }
"

echo "[Mongo Router Init] Router initialization completed!"
