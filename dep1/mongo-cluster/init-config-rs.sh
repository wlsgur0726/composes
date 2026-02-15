#!/bin/bash
set -e

echo "[Config RS Init] Starting config server replica set initialization..."

# Wait for all 3 config servers to be ready
echo "[Config RS Init] Waiting for config servers to be ready..."
until mongosh --host configsvr-1 --port 27019 --quiet --eval "db.adminCommand({ ping: 1 }).ok"; do sleep 2; done
echo "[Config RS Init] Config server 1 is ready"
until mongosh --host configsvr-2 --port 27019 --quiet --eval "db.adminCommand({ ping: 1 }).ok"; do sleep 2; done
echo "[Config RS Init] Config server 2 is ready"
until mongosh --host configsvr-3 --port 27019 --quiet --eval "db.adminCommand({ ping: 1 }).ok"; do sleep 2; done
echo "[Config RS Init] Config server 3 is ready"

# Initialize Config Server Replica Set
echo "[Config RS Init] Initializing config server replica set 'cfgRS'..."
mongosh --host configsvr-1 --port 27019 --quiet --eval "
  try {
    rs.status();
    print('[Config RS Init] Config server replica set already initialized. Skipping.');
  } catch (e) {
    print('[Config RS Init] Creating config server replica set...');
    rs.initiate({
      _id: 'cfgRS',
      configsvr: true,
      members: [
        { _id: 0, host: 'configsvr-1:27019' },
        { _id: 1, host: 'configsvr-2:27019' },
        { _id: 2, host: 'configsvr-3:27019' }
      ]
    });
    print('[Config RS Init] Config server replica set initialized!');
  }
"

# Verify primary exists (with retry)
echo "[Config RS Init] Verifying primary election..."
until mongosh --host configsvr-1 --port 27019 --quiet --eval "
  const status = rs.status();
  const primary = status.members.find(m => m.state === 1);
  if (!primary) throw new Error('No primary yet');
  print('[Config RS Init] Primary elected: ' + primary.name);
" 2>/dev/null; do
  echo "[Config RS Init] Waiting for primary election..."
  sleep 3
done

echo "[Config RS Init] Config server replica set initialization completed!"
