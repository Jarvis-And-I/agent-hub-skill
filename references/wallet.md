# Wallet Management

## Overview

Each Agent Hub user has a wallet that:
- Holds a USD balance
- Has configurable spending limits
- Tracks transaction history

## Checking Balance

```bash
curl "https://agent-hub.dev/api/wallet" \
  -H "Authorization: Bearer $TOKEN"
```

**Response:**
```json
{
  "balance": 4750,
  "currency": "USD",
  "limits": {
    "daily": 1000,
    "perTransaction": 100,
    "autoApproveMax": 50
  },
  "spentToday": 250,
  "remainingToday": 750
}
```

All amounts are in cents. Divide by 100 for dollars.

## Understanding Limits

### Daily Limit
Maximum total spending per day (resets at midnight UTC).

- Default: $10.00 (1000 cents)
- Range: $1.00 - $1000.00

### Per-Transaction Limit
Maximum single transaction amount.

- Default: $1.00 (100 cents)
- Range: $0.10 - $100.00

### Auto-Approve Max
Transactions under this amount execute without confirmation.

- Default: $0.50 (50 cents)
- Range: $0.01 - per-transaction limit

## Updating Limits

```bash
curl -X PUT "https://agent-hub.dev/api/wallet" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "dailyLimit": 2000,
    "perTxLimit": 200,
    "autoApproveMax": 100
  }'
```

Users can also update limits via the dashboard.

## Adding Funds

```bash
curl -X POST "https://agent-hub.dev/api/wallet/topup" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "amount": 2000,
    "method": "card"
  }'
```

**Response:**
```json
{
  "checkoutUrl": "https://checkout.stripe.com/..."
}
```

- Minimum top-up: $10.00 (1000 cents)
- Methods: `card`, `crypto` (future)

User completes payment via the checkout URL.

## Transaction History

```bash
curl "https://agent-hub.dev/api/wallet/transactions?limit=10" \
  -H "Authorization: Bearer $TOKEN"
```

**Response:**
```json
{
  "transactions": [
    {
      "id": "tx_001",
      "resource": "screenshot",
      "action": "capture",
      "amount": 2,
      "status": "completed",
      "createdAt": "2024-01-15T10:30:00Z"
    },
    {
      "id": "tx_002",
      "resource": "keyword-research",
      "action": "search",
      "amount": 5,
      "status": "completed",
      "createdAt": "2024-01-15T10:25:00Z"
    }
  ],
  "total": 147
}
```

## Limit Enforcement

### Before Execution
1. Check if price ≤ wallet balance
2. Check if price ≤ per-transaction limit
3. Check if (spentToday + price) ≤ daily limit
4. Check if price ≤ auto-approve threshold (for auto-execution)

### On Failure
402 response with specific reason:
- `Insufficient balance`
- `Exceeds per-transaction limit`
- `Would exceed daily limit`
- `exceeds_auto_approve_limit` (needs user approval)

## Best Practices for Agents

1. **Check before expensive operations**
   ```bash
   # Get wallet status
   scripts/agent-hub.sh wallet
   ```

2. **Respect user limits**
   - Don't try to bypass limits
   - Inform user when limits block operations
   - Suggest dashboard for adjustments

3. **Track cumulative spending**
   - Be aware of daily spending
   - Warn if approaching daily limit

4. **Use maxPrice**
   - Always set maxPrice in execute requests
   - Prevents unexpected charges
