#!/bin/bash
set -e

exec mongod \
  --shardsvr \
  --replSet "${ARG_MONGO_REPLSET_NAME}" \
  --bind_ip_all
