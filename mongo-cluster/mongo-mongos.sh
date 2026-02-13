#!/bin/bash
set -e

exec mongos \
  --configdb "${KJH_MONGO_CONFIGDB}" \
  --bind_ip_all
