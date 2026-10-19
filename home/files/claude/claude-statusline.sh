# shellcheck shell=bash
# Claude Code statusline: the oh-my-posh line, then whether this session's prompt cache is still warm.
# Status line JSON on stdin. See docs/design/claude-cache-statusline.md

json=$(cat)
printf '%s' "$json" | oh-my-posh claude --config "$HOME/.config/oh-my-posh/claude.yaml"

transcript=$(jq -r '.transcript_path // empty' <<<"$json")
[[ -r $transcript ]] || exit 0

# shortcut: reads only the last 500 lines, so a long run of huge tool results hides the last request; widen if the segment misreads.
tail -n 500 "$transcript" | jq -Rnr '
  # fromjson? skips a line Claude Code is still writing.
  [inputs | fromjson? | select(.type == "assistant" and .message.usage)] as $requests
  | ($requests | map(.message.usage.cache_creation // {}
      | select((.ephemeral_5m_input_tokens // 0) + (.ephemeral_1h_input_tokens // 0) > 0)) | last) as $write
  | if $requests == [] then "  |  cache cold"
    elif $write == null then empty
    else (if ($write.ephemeral_1h_input_tokens // 0) > 0 then 3600 else 300 end) as $ttl
      | ($ttl - (now - ($requests[-1].timestamp | sub("\\.[0-9]+Z$"; "Z") | fromdate))) as $left
      | "  |  cache \(if $left > 0 then "warm \($left / 60 | floor)m" else "cold" end)/\(if $ttl == 3600 then "1h" else "5m" end)"
    end'
