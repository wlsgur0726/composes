#!/bin/bash
set -e

exec mongod \
  --replSet rs0 \
  --bind_ip_all
