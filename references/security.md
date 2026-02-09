# Security Model

## Request Signing

All authenticated requests are cryptographically signed. Even if someone steals your token, they can't use it without your private key.

### How It Works

```
┌─────────────────────────────────────────────────────────────┐
│  During Connection                                          │
│                                                             │
│  1. Agent generates keypair (ECDSA P-256)                   │
│  2. Public key sent to Agent Hub during linking             │
│  3. Private key stored locally, never transmitted           │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│  Every Request                                              │
│                                                             │
│  1. Agent creates payload: timestamp + hash(body)           │
│  2. Agent signs payload with private key                    │
│  3. Signature included in X-Signature header                │
│  4. Server verifies signature with stored public key        │
└─────────────────────────────────────────────────────────────┘
```

### Request Headers

```http
POST /api/resources/screenshot/execute
Authorization: Bearer cb_your_token
X-Timestamp: 2024-01-15T10:30:00Z
X-Body-Hash: sha256_of_request_body_base64
X-Signature: signature_of_timestamp:bodyhash_base64
Content-Type: application/json

{"action": "capture", "params": {"url": "https://example.com"}}
```

### Signature Payload

```
payload = timestamp + ":" + bodyHash
signature = sign(payload, privateKey)
```

- `timestamp`: ISO8601 UTC timestamp
- `bodyHash`: Base64 SHA-256 hash of request body (empty string for GET)
- `sign`: ECDSA-SHA256 or RSA-SHA256

### Why This Matters

**Traditional API key:**
```
Token stolen → Attacker has full access
```

**Signed requests:**
```
Token stolen → Attacker has token
              → But no private key
              → Can't generate valid signatures
              → Requests rejected
```

## Key Storage

```
~/.clawdbot/skills/agent-hub/
├── config.json      (600) Token and settings
├── private.pem      (600) Private key - NEVER SHARE
└── public.pem       (644) Public key - registered with Agent Hub
```

- Private key permissions: `600` (owner read/write only)
- Private key location: Never leaves the agent's filesystem
- If compromised: Disconnect and reconnect with new keypair

## Replay Attack Prevention

Requests include a timestamp. Server rejects:
- Timestamps more than 5 minutes old
- Timestamps in the future

This prevents attackers from capturing and replaying signed requests.

## Wallet Limits (Defense in Depth)

Even with valid signatures, spending is limited:

| Limit | Default | Purpose |
|-------|---------|---------|
| Wallet balance | User-funded | Maximum possible spend |
| Daily limit | $10.00 | Max per 24 hours |
| Per-transaction | $1.00 | Max single charge |
| Auto-approve | $0.50 | Needs approval above this |

## Threat Model

### Token Theft
- **Attack:** Someone steals your token from config
- **Mitigation:** Token useless without private key
- **Action:** Signature verification rejects requests

### Private Key Theft
- **Attack:** Someone steals your private key file
- **Mitigation:** They still need the token, file permissions help
- **Action:** Disconnect in dashboard, reconnect with new keypair

### Man-in-the-Middle
- **Attack:** Intercept requests in transit
- **Mitigation:** HTTPS encrypts traffic
- **Action:** Can't read or modify requests

### Replay Attack
- **Attack:** Capture valid signed request, replay it
- **Mitigation:** Timestamp verification (5 min window)
- **Action:** Old requests rejected

### Compromised Agent
- **Attack:** Agent itself is compromised/jailbroken
- **Mitigation:** Wallet limits cap damage
- **Action:** Max loss = wallet balance (user controls deposits)

## Best Practices

1. **Protect your private key**
   - Ensure `private.pem` has 600 permissions
   - Never copy it to other systems
   - Never include it in backups to cloud

2. **Set appropriate limits**
   - Only deposit what you're willing to lose
   - Set daily limits based on expected usage
   - Lower auto-approve for sensitive use cases

3. **Monitor usage**
   - Check dashboard for unexpected transactions
   - Review connected agents periodically
   - Disconnect unused connections

4. **Rotate if suspicious**
   - If you suspect compromise, disconnect immediately
   - Delete old keypair
   - Reconnect with fresh credentials
