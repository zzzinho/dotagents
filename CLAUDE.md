# CLAUDE.md

개인용 Claude Code 플러그인 마켓플레이스 (`zzzinho`).

## 구조

- `.claude-plugin/marketplace.json` — 마켓플레이스 목록
- `plugins/<name>/.claude-plugin/plugin.json` — 플러그인 manifest
- `plugins/statusline/scripts/statusline-command.sh` — `~/.claude/settings.json` 의 `statusLine` 이 이 경로를 직접 실행한다. 옮기거나 이름을 바꾸면 settings 도 같이 고칠 것.
- `plugins/agents/agents/*.md` — 서브에이전트. `agents:<name>` 으로 로드된다. `~/.claude/agents` 는 쓰지 않는다.
- `plugins/vault/skills/vault/SKILL.md` — `vault:vault` 스킬. `~/.claude/skills` 에는 claude.ai 동기화 스킬(`synced/`)만 둔다.

## 적용

이 저장소는 로컬 폴더 마켓플레이스(`claude plugin marketplace add ~/dotagents`)로 등록돼 있어 폴더를 직접 읽는다. 수정은 다음 세션이나 `/reload-plugins` 에서 반영된다. 새 플러그인은 `claude plugin install <name>@zzzinho`.

## 검증

```bash
claude plugin validate .
claude plugin validate plugins/<name>
```

README·아이콘 경고는 공식 디렉토리 제출용이라 무시한다.

## 방향성

- 지금은 Claude Code 만 지원한다.
- 나중에 Codex·Antigravity 도 이 저장소에서 관리할 수 있게 한다. 그래서 특정 도구에 묶이는 결정은 피한다.
- 다른 도구를 지원할 때는 그 도구의 네이티브 파일을 따로 둔다. Codex 가 `.claude-plugin/` 을 읽어주는 호환 경로에 기대지 않는다.

### 확장할 때 참고 (2026-10-24 실측, codex-cli 0.157.1 · agy 1.0.13)

- 공용: `skills/<name>/SKILL.md` 는 세 도구가 그대로 읽는다.
- Codex
  - 마켓플레이스: `.agents/plugins/marketplace.json` (`policy` 필수). 있으면 `.claude-plugin/marketplace.json` 보다 우선한다.
  - manifest: `.codex-plugin/plugin.json` (`"skills": "./skills/"`). 있으면 `.claude-plugin/plugin.json` 보다 우선한다. 루트 `plugin.json` 은 이 둘보다 밀린다.
  - 에이전트는 플러그인 구성 요소가 아니다. `~/.codex/agents/*.toml` (`name`, `description`, `developer_instructions`).
- Antigravity
  - 직접 만든 마켓플레이스 미지원. 플러그인 단위로 `agy plugin install <로컬 경로|GitHub URL>`.
  - manifest: 플러그인 루트 `plugin.json`. `skills/`, `agents/*.md`, `rules/`, `hooks.json`, `mcp_config.json`.
  - `agents/*.md` 의 `tools` 는 Antigravity 도구 이름이다. Claude 도구 이름(`Read`, `Edit` …)을 그대로 두면 subagent 가 멈출 수 있다고 문서에 경고돼 있다.
  - 워크스페이스의 `.agents/` 를 읽으므로 Codex 용 `.agents/plugins/` 와 경로가 겹친다.
- statusline 은 도구마다 자기 settings 에서 설정하므로 공유 대상이 아니다.
