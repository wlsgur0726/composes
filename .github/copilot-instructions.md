# 주요 지침

- 제공할 compose를 `/dep{N}/시스템/compose.yml` 경로에 작성
  - N은 의존성을 나타냄. 0은 의존성이 없는 시스템, 1은 0에 의존하는 시스템, 2는 1에 의존하는 시스템, ...

- rootless podman 기준으로 작성, 명령도 podman 기반, docker 호환성 유지

- 모든 compose는 `shared-net` 네트워크를 사용하도록 설정
  ```yml
  networks:
    default:
      name: shared-net
      external: true
      driver: bridge
  ```

- 모든 compose는 첫줄에 제품명 주석으로 시작

- 포트, 볼륨 등은 특별한 이유가 없는 한 기본값 사용

- command 항목이 많아지면 위에서 아래로 읽기 편하도록 list 사용

- redis 처럼 클라이언트에게 자신의 주소를 announce하고, 클라이언트가 그것을 사용해야 하는 경우, `host.containers.internal`로 announce하도록 설정

- 여러 서비스가 있는 파일에서 반복적인 패턴(샤드)들은 entrypoint 스크립트와 환경변수 조합 등으로 처리하도록 노력. 이때, 환경변수는 `ARG_제품명_` 접두어로 시작하도록 작명(예: `ARG_REDIS_CLUSTER_PORT`)
