# Authentication

## Overview

Agent Hub uses token-based authentication. Tokens are obtained through a linking code flow that connects your Clawdbot instance to a user's Agent Hub account.

## Linking Flow

### Step 1: User generates a code

User visits https://agent-hub.dev/dashboard and clicks "Generate Linking Code".

They receive an 8-character code like: `A1B2C3D4`

### Step 2: User provides code to agent

User tells their agent: "Connect to Agent Hub with code A1B2C3D4"

### Step 3: Agent connects

```bash
curl -X POST "https://agent-hub.dev/api/auth/connect" \
  -H "Content-Type: application/json" \
  -d '{
    "code": "A1B2C3D4",
    "clawdbotId": "unique-instance-identifier",
    "hostname": "my-server"
  }'
```

**Request Body:**
- `code` (required): The linking code from user
- `clawdbotId` (required): Unique identifier for this Clawdbot instance
- `hostname` (optional): Server hostname for identification
- `clawdbotVersion` (optional): Clawdbot version string

### Step 4: Receive token

```json
{
  "success": true,
  "token": "cb_abc123def456...",
  "message": "Successfully connected to Agent Hub",
  "connection": {
    "clawdbotId": "unique-instance-identifier",
    "connectedAt": "2024-..."
  }
}
```

### Step 5: Store token

Save the token securely for future requests.

Recommended location: `~/.clawdbot/skills/agent-hub/config.json`

```json
{
  "token": "cb_abc123def456...",
  "apiUrl": "https://agent-hub.dev/api"
}
```

## Using the Token

Include the token in the Authorization header for all authenticated requests:

```
Authorization: Bearer cb_abc123def456...
```

## Verifying Connection

Check if your token is valid:

```bash
curl "https://agent-hub.dev/api/auth/me" \
  -H "Authorization: Bearer cb_abc123def456..."
```

**Response:**
```json
{
  "authenticated": true,
  "userId": "user_123",
  "clawdbotId": "unique-instance-identifier"
}
```

## Error Codes

### Invalid code
```json
{ "error": "Invalid code" }
```
The code doesn't exist or was typed wrong.

### Code expired
```json
{ "error": "Code expired" }
```
Codes expire after 10 minutes. Ask user for a new one.

### Code already used
```json
{ "error": "Code already used" }
```
Each code can only be used once.

### Not authenticated (401)
```json
{ "error": "Not authenticated", "authenticated": false }
```
Token is missing, invalid, or expired.

## Security Notes

1. **Keep tokens secret** — Never log or expose tokens
2. **Store securely** — Use appropriate file permissions (600)
3. **One token per instance** — Each Clawdbot instance gets its own token
4. **Revocation** — Users can disconnect from dashboard
