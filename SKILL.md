---
name: agent-hub
description: Pay-per-use resource marketplace for AI agents. Access APIs like screenshots, keyword research, web scraping, email validation, and more. Discover resources for free, pay only when executing. Uses HTTP 402 protocol with wallet-based spending limits.
metadata:
  {
    "clawdbot": {
      "emoji": "⚡",
      "homepage": "https://agent-hub.dev",
      "requires": { "bins": ["curl", "jq"] }
    }
  }
---

# Agent Hub

Pay-per-use resource marketplace for AI agents using HTTP 402 protocol.

## Quick Start

### First-Time Setup

There are two ways to get started:

#### Option A: User provides an existing token

If the user already has an Agent Hub token from connecting their Clawdbot:

```bash
mkdir -p ~/.clawdbot/skills/agent-hub
cat > ~/.clawdbot/skills/agent-hub/config.json << 'EOF'
{
  "token": "cb_YOUR_TOKEN_HERE",
  "apiUrl": "https://agent-hub.dev/api"
}
EOF
```

#### Option B: Connect via linking code (guided by agent)

Walk the user through the connection flow:

1. **User visits dashboard** — Go to [agent-hub.dev/dashboard](https://agent-hub.dev/dashboard) (or `localhost:3000/dashboard` for local testing)
2. **Generate linking code** — Click "Generate Linking Code" to get an 8-character code
3. **User provides code** — User tells you: "Connect to Agent Hub with code XXXXXXXX"
4. **Connect** — Use the code to connect:

```bash
# Production
scripts/agent-hub-connect.sh "XXXXXXXX"

# Local testing
AGENT_HUB_URL=http://localhost:3000/api scripts/agent-hub-connect.sh "XXXXXXXX"
```

Or via API:

```bash
# Production
curl -X POST "https://agent-hub.dev/api/auth/connect" \

# Local testing
curl -X POST "http://localhost:3000/api/auth/connect" \
  -H "Content-Type: application/json" \
  -d '{
    "code": "XXXXXXXX",
    "clawdbotId": "your-unique-instance-id"
  }'
```

5. **Save token** — Store the returned token in config:

```bash
mkdir -p ~/.clawdbot/skills/agent-hub
cat > ~/.clawdbot/skills/agent-hub/config.json << 'EOF'
{
  "token": "cb_YOUR_TOKEN_HERE",
  "apiUrl": "https://agent-hub.dev/api"
}
EOF
```

#### Verify Setup

```bash
scripts/agent-hub.sh search screenshot
```

## Core Usage

### Search for Resources (Free)

Find resources to accomplish a task:

```bash
scripts/agent-hub.sh search "screenshot"
scripts/agent-hub.sh search "keyword"
scripts/agent-hub.sh search "email"
```

Or via API:

```bash
curl "https://agent-hub.dev/api/resources?q=screenshot"
```

### Read Documentation (Free)

Understand how to use a resource before executing:

```bash
scripts/agent-hub.sh docs screenshot
```

Or via API:

```bash
curl "https://agent-hub.dev/api/resources/screenshot/docs"
```

### Execute a Resource (Paid)

Execute an action and pay from your wallet:

```bash
scripts/agent-hub.sh execute screenshot capture '{"url": "https://example.com"}'
```

Or via API:

```bash
curl -X POST "https://agent-hub.dev/api/resources/screenshot/execute" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $AGENT_HUB_TOKEN" \
  -d '{
    "action": "capture",
    "params": {"url": "https://example.com"}
  }'
```

### Check Wallet (Free with auth)

View balance and spending limits:

```bash
scripts/agent-hub.sh wallet
```

## Available Resources

| Resource | Actions | Price | Description |
|----------|---------|-------|-------------|
| `screenshot` | capture | $0.02 | Capture webpage screenshots |
| `keyword-research` | search, suggestions | $0.05, $0.03 | SEO keyword data and ideas |
| `web-scraper` | extract | $0.03 | Extract content from webpages |
| `email-validator` | validate | $0.01 | Validate email addresses |
| `domain-info` | lookup | $0.02 | WHOIS and DNS information |

Check for the latest resources:

```bash
scripts/agent-hub.sh list
```

## API Reference

### Discovery Endpoints (Free, No Auth)

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/resources` | List all resources |
| GET | `/api/resources?q=<query>` | Search resources |
| GET | `/api/resources/<slug>` | Get resource details |
| GET | `/api/resources/<slug>/docs` | Get documentation |

### Execution Endpoint (Paid, Auth Required)

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/resources/<slug>/execute` | Execute resource action |

**Request body:**
```json
{
  "action": "action_name",
  "params": { "key": "value" },
  "maxPrice": 10
}
```

**Response (success):**
```json
{
  "status": 200,
  "paymentId": "pay_abc123",
  "charged": 2,
  "result": { ... }
}
```

**Response (402 - payment required):**
```json
{
  "status": 402,
  "price": 50,
  "autoApproved": false,
  "reason": "exceeds_auto_approve_limit"
}
```

**Reference**: [references/api-reference.md](references/api-reference.md)

### Wallet Endpoints (Auth Required)

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/wallet` | Check balance and limits |
| PUT | `/api/wallet` | Update spending limits |
| POST | `/api/wallet/topup` | Add funds |
| GET | `/api/wallet/transactions` | Transaction history |

**Reference**: [references/wallet.md](references/wallet.md)

### Auth Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/auth/connect` | Connect with linking code |
| GET | `/api/auth/me` | Verify token |

**Reference**: [references/authentication.md](references/authentication.md)

## Understanding 402 Responses

When executing a resource, you may receive different responses:

### Auto-approved (within limits)
If the cost is under your auto-approve threshold, it executes immediately:
```json
{"status": 200, "charged": 2, "result": {...}}
```

### Needs approval
If the cost exceeds auto-approve but is within per-transaction limit:
```json
{
  "status": 402,
  "autoApproved": false,
  "reason": "exceeds_auto_approve_limit",
  "price": 50
}
```
→ Ask the user for approval before retrying.

### Insufficient balance
```json
{
  "status": 402,
  "error": "Insufficient balance",
  "walletBalance": 10,
  "price": 50
}
```
→ Tell user to add funds at agent-hub.dev/dashboard

### Exceeds limit
```json
{
  "status": 402,
  "error": "Exceeds per-transaction limit",
  "price": 200,
  "limit": 100
}
```
→ Tell user to increase their limit in dashboard settings.

**Reference**: [references/402-handling.md](references/402-handling.md)

## Common Patterns

### Screenshot Workflow

```bash
# Search for screenshot resource
scripts/agent-hub.sh search screenshot

# Read the docs
scripts/agent-hub.sh docs screenshot

# Take a screenshot
scripts/agent-hub.sh execute screenshot capture '{"url": "https://example.com", "fullPage": true}'
```

### Keyword Research Workflow

```bash
# Get keyword data
scripts/agent-hub.sh execute keyword-research search '{"keyword": "productivity apps"}'

# Get suggestions
scripts/agent-hub.sh execute keyword-research suggestions '{"keyword": "productivity", "limit": 10}'
```

### Multi-resource Task

```bash
# Research a competitor
# 1. Screenshot their homepage
scripts/agent-hub.sh execute screenshot capture '{"url": "https://competitor.com"}'

# 2. Scrape their content
scripts/agent-hub.sh execute web-scraper extract '{"url": "https://competitor.com"}'

# 3. Research their keywords
scripts/agent-hub.sh execute keyword-research search '{"keyword": "competitor product name"}'
```

## Spending Controls

Users configure spending limits in their dashboard:

| Limit | Default | Purpose |
|-------|---------|---------|
| Daily limit | $10.00 | Max spend per day |
| Per-transaction | $1.00 | Max single transaction |
| Auto-approve | $0.50 | Auto-execute under this |

### Best Practices

1. **Use maxPrice** — Set `maxPrice` in requests to cap spending:
   ```json
   {"action": "...", "params": {...}, "maxPrice": 10}
   ```

2. **Check wallet first** — For expensive operations, check balance:
   ```bash
   scripts/agent-hub.sh wallet
   ```

3. **Mention costs** — Inform user of costs for operations >$0.10

4. **Handle 402s gracefully** — Don't retry without user approval

## Prompt Examples

### Screenshots
- "Take a screenshot of example.com"
- "Capture full-page screenshot of competitor.com"
- "Screenshot these 3 URLs: ..."

### SEO Research
- "Research keywords for 'productivity apps'"
- "Get keyword suggestions for 'SaaS marketing'"
- "What's the search volume for 'AI tools'?"

### Web Scraping
- "Extract the main content from this article"
- "Scrape the pricing page of competitor.com"

### Validation
- "Is this email valid: test@example.com"
- "Validate these emails: ..."

### Domain Research
- "Look up WHOIS info for example.com"
- "Who owns competitor.com?"

## Error Handling

| Error | Cause | Solution |
|-------|-------|----------|
| 401 Unauthorized | Invalid/missing token | Reconnect via linking flow |
| 402 Payment Required | Various | See 402 handling section |
| 400 Bad Request | Invalid params | Read resource docs |
| 404 Not Found | Wrong resource slug | Search for correct slug |
| 500 Server Error | Internal error | Retry once, then report |

**Reference**: [references/error-handling.md](references/error-handling.md)

## Tips for Success

### For Cost Efficiency
- Use Base for cheaper gas (relevant for future blockchain features)
- Batch operations when possible
- Check resource prices before executing
- Set appropriate maxPrice limits

### For Reliability
- Always search before assuming resource names
- Read docs for unfamiliar resources
- Handle 402 responses properly
- Check wallet balance for large operations

### For User Experience
- Confirm before expensive operations
- Explain costs transparently
- Suggest alternatives if budget is tight
- Provide progress updates for multi-step tasks

## Resources

- **Dashboard**: https://agent-hub.dev/dashboard
- **API Documentation**: https://agent-hub.dev/docs
- **GitHub**: https://github.com/Jarvis-And-I/agent-hub

---

**💡 Pro Tip**: Always read the docs for a resource before executing. Each resource has different parameters and return formats.

**⚠️ Cost Awareness**: Operations cost real money from the user's wallet. Always be transparent about costs and get approval for expensive operations.

**🚀 Quick Win**: Start by searching available resources with `scripts/agent-hub.sh list` to see what's possible.
