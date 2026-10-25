# dotagents

개인용 Claude Code 플러그인 마켓플레이스 (`zzzinho`).

| 플러그인 | 내용 |
|---|---|
| `agents` | 서브에이전트 (Go, Swift, 디자인 doc, Dockerfile, k8s infra/ops) |
| `vault` | `~/vault` 에 검증한 지식을 저장하는 스킬 |
| `statusline` | 2줄 statusline 스크립트 (`jq` 필요) |

## 설치

```bash
claude plugin marketplace add zzzinho/dotagents
claude plugin install agents@zzzinho
claude plugin install vault@zzzinho
```

실행 중인 세션에는 `/reload-plugins` 로 반영한다.

statusline 은 플러그인으로 설치되지 않는다. `~/.claude/settings.json` 에 직접 추가한다.

```json
"statusLine": {
  "type": "command",
  "command": "bash ~/.claude/plugins/marketplaces/zzzinho/plugins/statusline/scripts/statusline-command.sh"
}
```

## 업데이트

```bash
claude plugin marketplace update zzzinho
claude plugin update agents@zzzinho
claude plugin update vault@zzzinho
```

## 제거

```bash
claude plugin uninstall agents@zzzinho
claude plugin uninstall vault@zzzinho
claude plugin marketplace remove zzzinho
```

statusline 을 썼다면 `~/.claude/settings.json` 의 `statusLine` 도 지운다.
