# Prompt Log

사용자 프롬프트와 Claude의 주요 응답을 기록합니다.

---

## 2026-11-27

### 1. 프로젝트를 Claude 프로젝트로 생성
**Prompt**
> 이 프로젝트를 클로드 프로젝트로 생성. .claude 폴더 생성, 스킬, 에이전트 폴더 생성

**Response**
- `.claude/settings.json`(팀 공유 설정, 빈 permissions), `.claude/skills/`, `.claude/agents/` 생성 (빈 폴더 추적용 `.gitkeep` 포함)
- `.gitignore`에 `.claude/settings.local.json` 추가
- `CLAUDE.md` 생성 (프로젝트 개요는 비워 둠)

### 2. 커밋 및 푸시
**Prompt**
> commit push

**Response**
- git 사용자 정보가 없어 첫 커밋 실패 → 첫 커밋 작성자 정보로 저장소 로컬 `user.name`/`user.email` 설정
- 커밋 `57b7942 Add Claude Code project structure` 생성 후 `origin/main`에 푸시

### 3. 프롬프트 기록 파일 생성
**Prompt**
> 지금까지 내가 작성한 프롬프트와 네가 답한 주요 내용은 prompt.md에 기록. 지속 관리

**Response**
- `prompt.md` 생성, 지금까지의 대화 기록
- `CLAUDE.md`에 매 프롬프트마다 `prompt.md`를 갱신하도록 규칙 추가

### 4. 커밋 및 푸시
**Prompt**
> commit push 후 요 보 인

**Response**
- `prompt.md`, `CLAUDE.md` 변경 사항 커밋 후 `origin/main`에 푸시
- "요 보 인"의 의미가 불명확해 사용자에게 확인 요청

### 5. 불완전한 프롬프트
**Prompt**
> 검

**Response**
- 입력이 한 글자("검")뿐이라 의도가 불명확해 사용자에게 확인 요청 (검색/검토/검증 등)

### 6. 현황 점검
**Prompt**
> 현황점검

**Response**
- 브랜치 `main`, `origin/main`과 동기화 상태. 미커밋 변경은 `prompt.md`뿐
- 구성: `.claude/settings.json`(권한 비어 있음), `skills/`·`agents/`는 빈 폴더, `CLAUDE.md` 프로젝트 개요 미작성
- 소스 코드 없음. 다음 단계로 프로젝트 목적 정의, 스킬/에이전트 추가 제안

### 7. 진행
**Prompt**
> 진행

**Response**
- 1단계(개요 작성)는 프로젝트 목적이 필요해 사용자에게 목적 확인 질문
- 사용자 답변: 목적은 "Clang 기반 C/C++ 개발", 커밋·푸시까지 진행
- `CLAUDE.md` 프로젝트 개요 작성, `README.md`에 요구 사항·빌드 방법 추가, `.gitignore`에 빌드 산출물(`build/`, `out/`, `compile_commands.json`, `.cache/`) 추가
- 커밋 후 `origin/main`에 푸시
- 원격에 사용자가 추가한 `스킬추가.md`(A-SPICE 기준 스킬 7종 명세) 커밋이 있어 rebase 후 푸시 (`025e8b2`)
- 다음 단계로 `스킬추가.md` 기반 스킬 생성 제안

### 8. 다음 단계 진행
**Prompt**
> 다음 단계 진행

**Response**
- `스킬추가.md` 명세대로 `.claude/skills/`에 스킬 7종 생성: `requirements-analysis`(SWE.1), `architecture-design`(SWE.2), `detailed-design`·`implementation`(SWE.3), `unit-test`(SWE.4), `integration-test`(SWE.5), `review`(SUP.4, `checklists.md`에 산출물별 체크리스트)
- LLVM 커버리지 스크립트 `unit-test/scripts/llvm_coverage.sh` 추가 (라인·브랜치·MC/DC 측정, 목표 대비 합격 판정). Clang 미설치로 실제 측정은 미검증, 문법·판정 로직만 검증
- `CLAUDE.md`에 프로세스 표·ID 체계·양방향 추적 규칙 추가, `docs/traceability.md` 골격, `.gitattributes`(`*.sh` LF 고정) 추가
- 로컬 커밋까지 진행, 푸시는 사용자 확인 후

### 9. 리뷰 서브에이전트 생성
**Prompt**
> 서브에이전트 생성
>
> 리뷰 서브에이전트
> 서브에이전트는 review 스킬을 적용한다.
> 분석, 설계, 구현, 테스트 등 각 단계가 완료되면, 이 리뷰 서브에이전트가 산출물의 품질을 리뷰한다.
> 리뷰 부적함 사항은 모두 조치완료해야 다음 단계로 넘어갈 수 있다.
> 단호하게 진행한다.(무자비하다, 봐주는것 없다.)

**Response**
- `.claude/agents/aspice-reviewer.md` 생성: `review` 스킬 적용(`skills: review`), 무관용 원칙(의심 시 NOK, 근거 없는 N/A 금지, 전수 검사, 수치 직접 재확인), `docs/reviews/` 외 수정 금지, 결함 직접 수정 금지
- `review` 스킬: 조건부 합격 폐지 → NOK 1건이라도 있으면 Fail. 리뷰는 작성자가 아닌 `aspice-reviewer`가 수행
- `CLAUDE.md`에 단계 게이트 추가: 단계 완료 시 리뷰 필수, 모든 NOK 조치·재리뷰 후 `Pass`여야 다음 단계 진행
- 각 단계 스킬의 리뷰 단계를 `aspice-reviewer` 호출로 변경

### 10. 리뷰어 모델 변경
**Prompt**
> 리뷰어 서브에이전트를 haiku 모델을 쓰도록 변경

**Response**
- `.claude/agents/aspice-reviewer.md` 프론트매터에 `model: haiku` 추가 후 커밋

### 11. 커밋 및 푸시
**Prompt**
> commit push

**Response**
- 로컬 커밋 3개(`bcc1793`, `063ce91`, `4d0cd5c`)와 이 기록을 `origin/main`에 푸시

### 12. 수정필요사항 반영
**Prompt**
> 수정필요사항.md 반영

(작업 중 추가 프롬프트)
> 스킬 정합
> 주석 20% 수준 충족 조건. 스킬에 반영
> gitflow 따라진행, 이후 작업 알아서 진행. 문제 발생시 원인 파악후 해결, 보고 필수. 환경 모두 구성 진행. 다만 내가 결정필요한 것은 제시

**Response**
- `CLAUDE.md` 전면 개정: A-SPICE·애자일 이터레이션(분석~시스템 테스트), 단계 게이트, 이터레이션 종료 시 사용자 확인 후 PR, TDD 분리 규칙, 품질 기준표, HITL doxygen 태그, Gitflow, 개발 환경, Jenkins
- 빌드 이미지 `claudeclangbuild` (`docker/Dockerfile`): Clang/LLVM 21.1.8, CMake 3.28, Ninja, GoogleTest/GMock, Cppcheck 2.13, Lizard, CLOC, Doxygen, PICT. 이미지 이름은 소문자만 허용되어 `ClaudeCLangBuild` → `claudeclangbuild`
  - 문제: PICT가 `-Werror`로 Clang 21 신규 경고에 빌드 실패 → PICT 빌드에서만 `-Werror` 제거
- 품질 게이트 `tools/quality_gate.sh` + `tools/check_hitl_comments.py`, `tools/check_requirements_coverage.py`, 커버리지 스크립트를 `tools/llvm_coverage.sh`로 이동(함수 커버리지·JUnit·report-only 추가)
  - 문제: Cppcheck `unusedFunction`(공개 API가 테스트에서만 호출) → 억제 대신 테스트 코드를 함께 분석해 해결
  - 문제: 주석률이 전체 평균으로만 계산되어 주석 없는 파일이 통과 → 파일별 20%도 강제. CMakeLists.txt가 CLOC에 포함되던 문제 → C/C++만 집계
  - 샘플 프로젝트로 전 스테이지 양성·음성 검증 완료
- Stop 훅 `.claude/hooks/lizard_check.sh`: 변경된 src/include에 Lizard(CCN≤10, 길이≤80), 위반 시 종료 차단. 3가지 경우 검증
- Jenkins LTS(Docker, 8080): `ci/jenkins/`(Dockerfile, plugins.txt, casc.yaml, docker-compose.yml), 관리자 비밀번호 `ci/jenkins/.env`(git 제외). 멀티브랜치 잡 `ClaudeClang` 생성 확인. `Jenkinsfile`: 이미지 안에서 스테이지별 게이트, Gitflow PR 규칙 검사, JUnit·Cppcheck·커버리지 리포트 게시
- 스킬 정합: implementation(TDD·HITL·주석률·Cppcheck/Lizard), unit-test(MC/DC 100%, GoogleTest), integration-test(함수 100%), detailed-design(80라인), requirements-analysis(시스템 테스트 입력), review 체크리스트(CODE-11~14, TDD, ST, CI 절 추가), sw-system-test-case(경로·ID·환경·구현 절), aspice-reviewer(게이트 직접 실행)
- Gitflow: `develop` 생성, `feature/dev-process-update`에서 작업 → develop으로 PR
