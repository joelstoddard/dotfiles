# Claude cache statusline

`claude-statusline` (`home/files/claude/claude-statusline.sh`) prints the oh-my-posh Claude
line, then `cache warm 52m/1h`, `cache cold/5m`, or `cache cold`. It answers one question
before you send a message: will this request read the session's prompt cache, or pay to
write it again?

## The TTL comes from the API response, not the plan

Claude Code picks a 1-hour cache TTL for subscribers and a 5-minute one otherwise, and it
also drops subscribers to 5 minutes in some cases (usage overage, for example). The status
line JSON does not say which TTL was used. Each assistant entry in the transcript does:
`message.usage.cache_creation` splits the tokens written into `ephemeral_5m_input_tokens`
and `ephemeral_1h_input_tokens`. The script takes the TTL from the latest request that wrote
cache, so the same script is right on a team plan, a personal plan, and in overage.

A request that only reads the cache refreshes its lifetime but writes nothing, so it does not
reset the TTL. The expiry is the last request's timestamp plus that TTL.

## States

| Output | Meaning |
|--------|---------|
| `cache warm Nm/TTL` | N whole minutes left before the cache expires |
| `cache cold/TTL` | the TTL has passed; the next request writes the cache again |
| `cache cold` | no request yet in this session |
| nothing | no transcript, or no request has written cache yet, so the TTL is unknown |

## Refresh

The status line normally redraws only on session events, so an idle session would never turn
cold. `statusLine.refreshInterval` (seconds) re-runs the command on a timer as well.

## Limits

1. Only the last 500 transcript lines are read, to keep a 30-second refresh cheap on long
   sessions.
2. A request that writes both TTLs is read as 1h. None was seen across 8,000 requests.
3. Expiry is measured from the transcript timestamp, which Claude Code writes when the
   response arrives, slightly after the API started the cache lifetime. The error is seconds.
