# ClaudeClang

Clang/LLVM 툴체인으로 C/C++ 코드를 A-SPICE 기준으로 개발하는 프로젝트입니다.
개발 절차·품질 기준·브랜치 전략은 [`CLAUDE.md`](CLAUDE.md)를 참고하세요.

## 개발 환경 (Docker)
개발과 CI 모두 같은 이미지 `claudeclangbuild`를 사용합니다
(Clang/LLVM 21, CMake, Ninja, GoogleTest/GMock, Cppcheck, Lizard, CLOC, Doxygen, PICT).

```sh
docker build -t claudeclangbuild docker
docker run --rm -it -v "$PWD:/workspace" claudeclangbuild          # 셸
docker run --rm -v "$PWD:/workspace" claudeclangbuild bash tools/quality_gate.sh   # 품질 게이트
```

## 품질 게이트
`tools/quality_gate.sh [build static metrics comments hitl unit tdd integration system]`

| 스테이지 | 기준 |
|---|---|
| build | Clang 경고 0 |
| static | Cppcheck 지적 0 |
| metrics | 순환 복잡도 ≤ 10, 함수 길이 ≤ 80 (Lizard) |
| comments | 주석률 ≥ 20% (CLOC, 파일별) |
| hitl | doxygen AI/리뷰 태그 |
| unit | MC/DC 100%, 성공률 100% |
| tdd | 성공률 100%, 커버리지 별도 리포트 |
| integration | 함수 커버리지 100%, 성공률 100% |
| system | 요구사항 커버리지 100% |

## CI (Jenkins)
```sh
echo "JENKINS_ADMIN_PASSWORD=<password>" > ci/jenkins/.env
docker compose -f ci/jenkins/docker-compose.yml --env-file ci/jenkins/.env up -d --build
```
http://localhost:8080 — 멀티브랜치 잡 `ClaudeClang`이 Gitflow 브랜치와 PR에 `Jenkinsfile`을 실행합니다.
