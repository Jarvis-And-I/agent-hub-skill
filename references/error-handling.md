# Error Handling

## HTTP Status Codes

| Code | Meaning | Action |
|------|---------|--------|
| 200 | Success | Process result |
| 400 | Bad Request | Check parameters |
| 401 | Unauthorized | Re-authenticate |
| 402 | Payment Required | See 402-handling.md |
| 404 | Not Found | Check resource slug |
| 500 | Server Error | Retry once |

## Common Errors

### Authentication Errors

#### Not authenticated
```json
{
  "error": "Not authenticated",
  "authenticated": false
}
```

**Cause:** Missing or invalid Authorization header.

**Solution:**
1. Check token is included: `Authorization: Bearer <token>`
2. Verify token is valid via `/api/auth/me`
3. If invalid, reconnect via linking flow

#### Invalid code (during connect)
```json
{ "error": "Invalid code" }
```

**Cause:** Linking code doesn't exist or was typed wrong.

**Solution:** Ask user to verify code or generate a new one.

#### Code expired
```json
{ "error": "Code expired" }
```

**Cause:** Linking codes expire after 10 minutes.

**Solution:** Ask user to generate a new code.

### Request Errors

#### Invalid request body
```json
{
  "error": "Invalid request body",
  "details": [
    { "path": ["action"], "message": "Required" }
  ]
}
```

**Cause:** Missing or malformed parameters.

**Solution:** Check request format against API docs.

#### Unknown action
```json
{
  "error": "Unknown action: foo. Available: capture"
}
```

**Cause:** Action doesn't exist for this resource.

**Solution:** Read resource docs for valid actions.

#### Resource not found
```json
{ "error": "Resource not found" }
```

**Cause:** Invalid resource slug.

**Solution:** Search for correct slug via `/api/resources?q=...`

### Execution Errors

#### Resource execution failed
```json
{
  "error": "Resource execution failed",
  "message": "Connection timeout"
}
```

**Cause:** The underlying resource API failed.

**Solution:**
1. Retry once after a short delay
2. If persistent, report to user
3. Check if resource is having issues

#### Price exceeds maxPrice
```json
{
  "error": "Price exceeds maxPrice",
  "price": 50,
  "maxPrice": 10
}
```

**Cause:** Actual price higher than your maxPrice limit.

**Solution:**
1. Inform user of actual cost
2. Retry without maxPrice if user approves
3. Or increase maxPrice

## Retry Strategy

### When to Retry
- 500 errors (server issues)
- Network timeouts
- Rate limiting (429)

### When NOT to Retry
- 400 errors (fix the request)
- 401 errors (fix authentication)
- 402 errors (handle payment)
- 404 errors (fix the slug)

### Retry Pattern
```
Attempt 1: Immediate
Attempt 2: Wait 1 second
Attempt 3: Wait 2 seconds
Give up after 3 attempts
```

## Error Reporting to Users

### Be Clear
❌ "Error occurred"
✅ "The screenshot service is temporarily unavailable"

### Be Actionable
❌ "Authentication failed"
✅ "Your Agent Hub connection expired. Please reconnect at agent-hub.dev/dashboard"

### Be Honest
❌ (silently fail)
✅ "I couldn't complete the keyword research. The service returned an error. Would you like me to try again?"

## Debugging

### Check Authentication
```bash
curl "https://agent-hub.dev/api/auth/me" \
  -H "Authorization: Bearer $TOKEN"
```

### Check Resource Exists
```bash
curl "https://agent-hub.dev/api/resources/screenshot"
```

### Check Resource Docs
```bash
curl "https://agent-hub.dev/api/resources/screenshot/docs"
```

### Check Wallet Status
```bash
curl "https://agent-hub.dev/api/wallet" \
  -H "Authorization: Bearer $TOKEN"
```
