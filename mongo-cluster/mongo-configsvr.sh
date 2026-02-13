#!/bin/bash
set -e

exec mongod \
  --configsvr \
  --replSet "${KJH_MONGO_REPLSET_NAME}" \
  --bind_ip_all
