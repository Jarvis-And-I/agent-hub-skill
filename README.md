# Agent Hub Skill

Pay-per-use resource marketplace skill for AI agents. Access APIs like screenshots, keyword research, web scraping, and more through Agent Hub.

## Installation

Give your agent this skill URL:

```
https://github.com/Jarvis-And-I/agent-hub-skill
```

Or tell your agent:

```
"Learn the Agent Hub skill from https://github.com/Jarvis-And-I/agent-hub-skill"
```

## Quick Start

1. **Install the skill** — Agent learns from this repo
2. **Get a linking code** — Visit [agent-hub.dev/dashboard](https://agent-hub.dev/dashboard)
3. **Connect** — Tell your agent: "Connect to Agent Hub with code XXXXXXXX"
4. **Use resources** — "Take a screenshot of example.com"

## Available Resources

| Resource | Action | Price | Description |
|----------|--------|-------|-------------|
| `screenshot` | capture | $0.02 | Capture webpage screenshots |
| `keyword-research` | search | $0.05 | SEO keyword data |
| `keyword-research` | suggestions | $0.03 | Related keyword ideas |
| `web-scraper` | extract | $0.03 | Extract webpage content |
| `email-validator` | validate | $0.01 | Validate email addresses |
| `domain-info` | lookup | $0.02 | WHOIS and DNS info |

## How It Works

```
Agent: "I need a screenshot of example.com"

1. GET /api/resources?q=screenshot
   → Found: screenshot ($0.02/capture)

2. POST /api/resources/screenshot/execute
   → 402 → Auto-paid → Result

3. Returns screenshot URL to user
```

## Files

| File | Purpose |
|------|---------|
| [SKILL.md](SKILL.md) | Main skill definition (agent reads this) |
| [scripts/](scripts/) | Bash helper scripts |
| [references/](references/) | Detailed API documentation |

## Links

- **Dashboard**: https://agent-hub.dev/dashboard
- **API Docs**: https://agent-hub.dev/docs
- **Platform Repo**: https://github.com/Jarvis-And-I/agent-hub

## License

MIT
