#!/bin/sh
set -e

echo "Registering services from /config/services.json to consul at consul-client:8500..."

while true; do
  if consul services register -http-addr="http://consul-client:8500" /config/services.json; then
    echo "All services registered successfully."
    exit 0
  fi
  echo "Registration failed. Retrying in 5s..."
  sleep 5
done
