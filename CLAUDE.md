# ClaudeClang

## 프로젝트 개요
Clang/LLVM 툴체인으로 C/C++ 코드를 작성·빌드하는 프로젝트.

- 컴파일러: `clang` / `clang++`
- 포맷·정적 분석: `clang-format`, `clang-tidy`
- 빌드 시스템: CMake (빌드 산출물은 `build/`, git 제외)

## Claude Code 구성
- `.claude/settings.json` — 팀 공유 설정 (권한, 훅 등)
- `.claude/settings.local.json` — 개인 설정 (git 제외)
- `.claude/skills/<skill-name>/SKILL.md` — 프로젝트 스킬
- `.claude/agents/<agent-name>.md` — 프로젝트 서브에이전트

## 작업 규칙
- **프롬프트 기록**: 사용자의 모든 프롬프트와 Claude의 주요 응답(수행한 작업, 결과, 결정 사항)을 `prompt.md`에 날짜별·번호순으로 계속 추가한다. 프롬프트는 원문 그대로 인용하고, 응답은 핵심만 요약한다.
