#!/bin/bash
set -e

echo "[Shard RS Init] Starting shard replica sets initialization..."

# Verify config RS has a primary (prerequisite)
echo "[Shard RS Init] Verifying config server replica set is ready..."
until mongosh --host configsvr-1 --port 27019 --quiet --eval "
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
until mongosh --host shard1-1 --port 27018 --quiet --eval "db.adminCommand({ ping: 1 }).ok"; do sleep 2; done
echo "[Shard RS Init] Shard 1 node 1 is ready"
until mongosh --host shard1-2 --port 27018 --quiet --eval "db.adminCommand({ ping: 1 }).ok"; do sleep 2; done
echo "[Shard RS Init] Shard 1 node 2 is ready"
until mongosh --host shard1-3 --port 27018 --quiet --eval "db.adminCommand({ ping: 1 }).ok"; do sleep 2; done
echo "[Shard RS Init] Shard 1 node 3 is ready"

until mongosh --host shard2-1 --port 27018 --quiet --eval "db.adminCommand({ ping: 1 }).ok"; do sleep 2; done
echo "[Shard RS Init] Shard 2 node 1 is ready"
until mongosh --host shard2-2 --port 27018 --quiet --eval "db.adminCommand({ ping: 1 }).ok"; do sleep 2; done
echo "[Shard RS Init] Shard 2 node 2 is ready"
until mongosh --host shard2-3 --port 27018 --quiet --eval "db.adminCommand({ ping: 1 }).ok"; do sleep 2; done
echo "[Shard RS Init] Shard 2 node 3 is ready"

until mongosh --host shard3-1 --port 27018 --quiet --eval "db.adminCommand({ ping: 1 }).ok"; do sleep 2; done
echo "[Shard RS Init] Shard 3 node 1 is ready"
until mongosh --host shard3-2 --port 27018 --quiet --eval "db.adminCommand({ ping: 1 }).ok"; do sleep 2; done
echo "[Shard RS Init] Shard 3 node 2 is ready"
until mongosh --host shard3-3 --port 27018 --quiet --eval "db.adminCommand({ ping: 1 }).ok"; do sleep 2; done
echo "[Shard RS Init] Shard 3 node 3 is ready"

# Initialize Shard 1 Replica Set
echo "[Shard RS Init] Initializing shard 1 replica set 'shard1RS'..."
mongosh --host shard1-1 --port 27018 --quiet --eval "
  try {
    rs.status();
    print('[Shard RS Init] Shard 1 replica set already initialized. Skipping.');
  } catch (e) {
    print('[Shard RS Init] Creating shard 1 replica set...');
    rs.initiate({
      _id: 'shard1RS',
      members: [
        { _id: 0, host: 'shard1-1:27018' },
        { _id: 1, host: 'shard1-2:27018' },
        { _id: 2, host: 'shard1-3:27018' }
      ]
    });
    print('[Shard RS Init] Shard 1 replica set initialized!');
  }
"

# Initialize Shard 2 Replica Set
echo "[Shard RS Init] Initializing shard 2 replica set 'shard2RS'..."
mongosh --host shard2-1 --port 27018 --quiet --eval "
  try {
    rs.status();
    print('[Shard RS Init] Shard 2 replica set already initialized. Skipping.');
  } catch (e) {
    print('[Shard RS Init] Creating shard 2 replica set...');
    rs.initiate({
      _id: 'shard2RS',
      members: [
        { _id: 0, host: 'shard2-1:27018' },
        { _id: 1, host: 'shard2-2:27018' },
        { _id: 2, host: 'shard2-3:27018' }
      ]
    });
    print('[Shard RS Init] Shard 2 replica set initialized!');
  }
"

# Initialize Shard 3 Replica Set
echo "[Shard RS Init] Initializing shard 3 replica set 'shard3RS'..."
mongosh --host shard3-1 --port 27018 --quiet --eval "
  try {
    rs.status();
    print('[Shard RS Init] Shard 3 replica set already initialized. Skipping.');
  } catch (e) {
    print('[Shard RS Init] Creating shard 3 replica set...');
    rs.initiate({
      _id: 'shard3RS',
      members: [
        { _id: 0, host: 'shard3-1:27018' },
        { _id: 1, host: 'shard3-2:27018' },
        { _id: 2, host: 'shard3-3:27018' }
      ]
    });
    print('[Shard RS Init] Shard 3 replica set initialized!');
  }
"

# Wait for all shard replica sets to elect primaries
echo "[Shard RS Init] Waiting for shard replica sets to elect primaries..."

for shard_host in shard1-1 shard2-1 shard3-1; do
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
