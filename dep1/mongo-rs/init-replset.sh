#!/bin/bash
set -e

echo "[Mongo RS Init] Starting replica set initialization..."

echo "[Mongo RS Init] Waiting for MongoDB nodes to be ready..."
until mongosh --host host.containers.internal --port 27017 --quiet --eval "db.adminCommand({ ping: 1 }).ok"; do
  sleep 2
done
echo "[Mongo RS Init] Node 1 (27017) is ready"

until mongosh --host host.containers.internal --port 27018 --quiet --eval "db.adminCommand({ ping: 1 }).ok"; do
  sleep 2
done
echo "[Mongo RS Init] Node 2 (27018) is ready"

until mongosh --host host.containers.internal --port 27019 --quiet --eval "db.adminCommand({ ping: 1 }).ok"; do
  sleep 2
done
echo "[Mongo RS Init] Node 3 (27019) is ready"

echo "[Mongo RS Init] Initializing replica set 'rs0'..."
mongosh --host host.containers.internal --port 27017 --quiet --eval "
  try {
    rs.status();
    print('[Mongo RS Init] Replica set already initialized. Skipping.');
  } catch (e) {
    print('[Mongo RS Init] Creating replica set configuration...');
    rs.initiate({
      _id: 'rs0',
      members: [
        { _id: 0, host: 'host.containers.internal:27017' },
        { _id: 1, host: 'host.containers.internal:27018' },
        { _id: 2, host: 'host.containers.internal:27019' }
      ]
    });
    print('[Mongo RS Init] Replica set initialization completed!');
  }
"

echo "[Mongo RS Init] Initialization process finished."
