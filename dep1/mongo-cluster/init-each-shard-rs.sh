#!/bin/bash
set -e

echo "[Shard RS Init] Starting shard replica sets initialization..."

# Wait for a node to be pingable
wait_for_node() {
  local host=$1
  local port=$2
  local label=$3
  until mongosh --host "$host" --port "$port" --quiet --eval "db.adminCommand({ ping: 1 }).ok"; do sleep 2; done
  echo "[Shard RS Init] ${label} is ready"
}

# Initialize a replica set (skips if already initialized)
init_replica_set() {
  local rs_name=$1
  local host=$2
  local port=$3
  local members_json=$4

  echo "[Shard RS Init] Initializing replica set '${rs_name}'..."
  mongosh --host "$host" --port "$port" --quiet --eval "
    try {
      rs.status();
      print('[Shard RS Init] ${rs_name} already initialized. Skipping.');
    } catch(e) {
      print('[Shard RS Init] Creating ${rs_name}...');
      rs.initiate(${members_json});
      print('[Shard RS Init] ${rs_name} initialized!');
    }
  "
}

# Verify config RS has a primary (prerequisite)
echo "[Shard RS Init] Verifying config server replica set is ready..."
until mongosh --host mongo-configsvr-1 --port 27019 --quiet --eval "
  const status = rs.status();
  const primary = status.members.find(m => m.state === 1);
  if (!primary) throw new Error('No primary');
  print('Config RS Primary: ' + primary.name);
" 2>/dev/null; do
  echo "[Shard RS Init] Waiting for config RS primary..."
  sleep 2
done
echo "[Shard RS Init] Config server replica set is ready with primary"

# Wait for all shard servers to be ready
echo "[Shard RS Init] Waiting for shard servers to be ready..."
for node in mongo-shard1-1 mongo-shard1-2 mongo-shard1-3 mongo-shard2-1 mongo-shard2-2 mongo-shard2-3 mongo-shard3-1 mongo-shard3-2 mongo-shard3-3; do
  wait_for_node "$node" 27018 "$node"
done

# Initialize shard replica sets
init_replica_set "shard1RS" "mongo-shard1-1" 27018 \
  '{ _id: "shard1RS", members: [{ _id: 0, host: "mongo-shard1-1:27018" }, { _id: 1, host: "mongo-shard1-2:27018" }, { _id: 2, host: "mongo-shard1-3:27018" }] }'

init_replica_set "shard2RS" "mongo-shard2-1" 27018 \
  '{ _id: "shard2RS", members: [{ _id: 0, host: "mongo-shard2-1:27018" }, { _id: 1, host: "mongo-shard2-2:27018" }, { _id: 2, host: "mongo-shard2-3:27018" }] }'

init_replica_set "shard3RS" "mongo-shard3-1" 27018 \
  '{ _id: "shard3RS", members: [{ _id: 0, host: "mongo-shard3-1:27018" }, { _id: 1, host: "mongo-shard3-2:27018" }, { _id: 2, host: "mongo-shard3-3:27018" }] }'

# Wait for all shard replica sets to elect primaries
echo "[Shard RS Init] Waiting for shard replica sets to elect primaries..."
for shard_host in mongo-shard1-1 mongo-shard2-1 mongo-shard3-1; do
  shard_name=$(echo $shard_host | sed 's/-[0-9]$//')
  echo "[Shard RS Init] Waiting for ${shard_name} primary..."
  until mongosh --host "$shard_host" --port 27018 --quiet --eval "
    const status = rs.status();
    const primary = status.members.find(m => m.state === 1);
    if (!primary) throw new Error('No primary');
    print('${shard_name} Primary: ' + primary.name);
  " 2>/dev/null; do
    sleep 3
  done
done

echo "[Shard RS Init] All shard replica sets initialization completed!"
