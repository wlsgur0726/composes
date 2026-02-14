# composes
- 로컬테스트용 compose 파일 모음.
- 특정 프로젝트에 종속적이지 않은, 범용적으로 사용할 수 있는 시스템들을 대상으로 함.

## 사전 구성
- ### shared-net 네트워크 생성
  - 서로 다른 compose 간 서비스 이름으로 통신하기 위한 목적
    ```bash
    podman network create shared-net
    ```

- ### hosts 수정 필요
  - redis처럼 자신의 주소를 `host.containers.internal`로 announce하고, 호스트가 그 주소로 접속할 필요가 있는 경우를 위함
  - 파일 위치
    - win: `C:\Windows\System32\drivers\etc\hosts`
    - mac: `/private/etc/hosts`
  - 다음 내용 추가
    ```
    # for Poddman
    127.0.0.1 host.containers.internal
    ```

## consul
- server, 3 nodes
- client 1 node 노출

## redis
버전 8 사용
- ### 공통
  - redis_exporter (docker.io/oliver006/redis_exporter)
  - redisinsight (docker.io/redis/redisinsight)
- ### [redis-cluster](./redis-cluster/compose.yml)
  - redis 3*2
- ### [redis-rs](./redis-rs/compose.yml)
  - 2 nodes + sentinel 3 nodes
  - sentinel proxy 1 node (envoy)

## mongo
버전 8 사용, [기본포트](https://www.mongodb.com/ko-kr/docs/manual/reference/default-mongodb-port/#default-mongodb-port) 사용하고 mongos의 LB만 노출
- ### 공통
  - mongodb_exporter (docker.io/percona/mongodb_exporter)
  - compass-web (docker.io/haohanyang/compass-web)
- ### [mongo-cluster](./mongo-cluster/compose.yml)
  - mongos proxy 1
  - mongos 3
  - configsvr 3
  - shard 3*3
- ### [mongo-rs](./mongo-rs/compose.yml)
  - 3 nodes

## loki
latest 버전 사용, 제약이 될만한 설정들 모두 완화

## tempo
latest 버전 사용, 제약이 될만한 설정들 모두 완화
