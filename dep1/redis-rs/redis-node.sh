#!/bin/sh
set -eu

# 공통 상수(모든 노드에서 동일하게 사용)
MASTER_NAME="mymaster"
SENTINEL_HOST="redis-sentinel-proxy"
SENTINEL_PORT="26379"
ANNOUNCE_IP="host.containers.internal"

# --- 기본 announce 정보 ---
# Sentinel/클라이언트가 이 노드를 식별할 때 사용할 주소/포트
announce_port="${ARG_REDIS_ANNOUNCE_PORT:?ARG_REDIS_ANNOUNCE_PORT is required}"

# --- Sentinel 질의 설정 ---
# 시작 시 Sentinel에 현재 master를 물어보고 role을 결정한다.
# Sentinel이 아직 수렴되지 않았을 때(응답 없음) 사용할 bootstrap 규칙
bootstrap_as_master="${ARG_REDIS_BOOTSTRAP_AS_MASTER:-false}"

# Sentinel에 현재 master 조회 (성공 시 1행=host, 2행=port)
master_info="$(redis-cli -h "${SENTINEL_HOST}" -p "${SENTINEL_PORT}" --raw SENTINEL get-master-addr-by-name "${MASTER_NAME}" 2>/dev/null || true)"
master_host="$(printf '%s' "${master_info}" | sed -n '1p')"
master_port="$(printf '%s' "${master_info}" | sed -n '2p')"

role="replica"
target_host=""
target_port=""

# Sentinel 응답이 있으면 그것을 신뢰해서 role 결정
if [ -n "${master_host}" ] && [ -n "${master_port}" ]; then
  # Sentinel이 가리키는 master 주소와 자기 announce 주소가 같으면 master 기동
  if [ "${master_host}" = "${ANNOUNCE_IP}" ] && [ "${master_port}" = "${announce_port}" ]; then
    role="master"
  else
    # 다르면 현재 master를 향하는 replica로 기동
    role="replica"
    target_host="${master_host}"
    target_port="${master_port}"
  fi
  echo "[redis-node] Sentinel master=${master_host}:${master_port}, self=${ANNOUNCE_IP}:${announce_port}, role=${role}"
else
  # Sentinel 응답이 없으면 env 기반 bootstrap 정책으로만 판단
  case "${bootstrap_as_master}" in
    1|true|TRUE|yes|YES|y|Y)
      role="master"
      ;;
    *)
      role="replica"
      # bootstrap replica가 따라갈 초기 master 주소(통상 redis-rs-1의 호스트 노출 포트)
      target_host="${ARG_REDIS_BOOTSTRAP_MASTER_HOST:-host.containers.internal}"
      target_port="${ARG_REDIS_BOOTSTRAP_MASTER_PORT:-6379}"
      ;;
  esac
  echo "[redis-node] Sentinel has no master response. bootstrap role=${role}"
fi

# master로 결정되면 replicaof 없이 기동
if [ "${role}" = "master" ]; then
  exec redis-server \
    --bind 0.0.0.0 \
    --protected-mode no \
    --appendonly yes \
    --replica-announce-ip "${ANNOUNCE_IP}" \
    --replica-announce-port "${announce_port}"
fi

# replica로 결정되면 결정된 target master를 따라가도록 기동
exec redis-server \
  --bind 0.0.0.0 \
  --protected-mode no \
  --appendonly yes \
  --replicaof "${target_host}" "${target_port}" \
  --replica-announce-ip "${ANNOUNCE_IP}" \
  --replica-announce-port "${announce_port}"