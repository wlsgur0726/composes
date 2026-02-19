#!/bin/sh
set -eu

# Build mongodb.uri step-by-step for readability.
MONGODB_URI="mongodb://"

# mongos routers
MONGODB_URI="${MONGODB_URI}mongos-1:27017"
MONGODB_URI="${MONGODB_URI},mongos-2:27017"
MONGODB_URI="${MONGODB_URI},mongos-3:27017"

# shard replica set members
MONGODB_URI="${MONGODB_URI},mongo-shard1-1:27017"
MONGODB_URI="${MONGODB_URI},mongo-shard1-2:27017"
MONGODB_URI="${MONGODB_URI},mongo-shard1-3:27017"

MONGODB_URI="${MONGODB_URI},mongo-shard2-1:27017"
MONGODB_URI="${MONGODB_URI},mongo-shard2-2:27017"
MONGODB_URI="${MONGODB_URI},mongo-shard2-3:27017"

MONGODB_URI="${MONGODB_URI},mongo-shard3-1:27017"
MONGODB_URI="${MONGODB_URI},mongo-shard3-2:27017"
MONGODB_URI="${MONGODB_URI},mongo-shard3-3:27017"

# query params
MONGODB_URI="${MONGODB_URI}/?directConnection=true"

exec mongodb_exporter \
  --collector.collstats-limit=0 \
  --collect-all=true \
  --collector.replicasetstatus=true \
  --collector.shards=true \
  --split-cluster=true \
  --mongodb.uri="${MONGODB_URI}"
