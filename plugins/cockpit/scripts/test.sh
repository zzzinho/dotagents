#!/bin/sh
# statusline-command.sh 출력 검사. 실행: sh plugins/cockpit/scripts/test.sh
dir=$(dirname "$0")
fail=0

# $1: 설명, $2: 입력 JSON, $3: 기대 줄 수, $4: 3번째 줄에 있어야 할 문자열 (없으면 생략)
check() {
  out=$(printf '%s' "$2" | sh "$dir/statusline-command.sh" | sed 's/\x1b\[[0-9;]*m//g')
  lines=$(printf '%s\n' "$out" | wc -l | tr -d ' ')
  line3=$(printf '%s\n' "$out" | sed -n '3p')
  if [ "$lines" != "$3" ] || { [ -n "$4" ] && ! printf '%s' "$line3" | grep -qF "$4"; }; then
    echo "FAIL: $1 (lines=$lines, line3=$line3)"; fail=1
  fi
}

base='"model":{"display_name":"Opus"},"cwd":"/tmp","rate_limits":{"five_hour":{"used_percentage":10}}'

check "warm + miss" "{$base,\"prompt_cache\":{\"caching_observed\":true,\"warm\":true,\"ttl\":\"1h\",\"expires_at\":1738429200,\"hit_ratio\":0.91,\"misses\":2,\"last_miss_cause\":{\"causes\":[\"tools_changed\"]}}}" 3 "Cache warm 1h"
check "miss cause" "{$base,\"prompt_cache\":{\"caching_observed\":true,\"warm\":true,\"hit_ratio\":0.91,\"misses\":2,\"last_miss_cause\":{\"causes\":[\"tools_changed\"]}}}" 3 "Miss 2 (tools_changed)"
check "cold, hit 0" "{$base,\"prompt_cache\":{\"caching_observed\":true,\"warm\":false,\"expires_at\":null,\"hit_ratio\":0,\"misses\":0}}" 3 "Cache cold  🎯 Hit 0%"
check "off" "{$base,\"prompt_cache\":{\"caching_observed\":false,\"warm\":false,\"hit_ratio\":null,\"misses\":0}}" 3 "Cache off"
check "no prompt_cache" "{$base}" 2

[ $fail -eq 0 ] && echo ok
exit $fail
