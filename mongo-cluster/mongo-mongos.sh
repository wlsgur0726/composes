#!/bin/bash
set -e

exec mongos \
  --configdb "${ARG_MONGO_CONFIGDB}" \
  --bind_ip_all
