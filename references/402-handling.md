# Handling 402 Responses

## Overview

HTTP 402 "Payment Required" is the core of Agent Hub's pay-per-use model. When you execute a resource, you may receive a 402 response indicating that payment handling is needed.

## Response Types

### Auto-Approved (200)

If the cost is within auto-approve limits, the request succeeds immediately:

```json
{
  "status": 200,
  "paymentId": "pay_abc123",
  "charged": 2,
  "result": { ... }
}
```

**Action:** Use the result normally.

### Needs Approval (402)

Cost exceeds auto-approve threshold but is within per-transaction limit:

```json
{
  "status": 402,
  "resource": "keyword-research",
  "action": "bulk",
  "price": 50,
  "walletBalance": 1000,
  "autoApproved": false,
  "reason": "exceeds_auto_approve_limit",
  "paymentId": "pay_xyz",
  "approvalUrl": "/api/payments/pay_xyz/approve"
}
```

**Action:** 
1. Inform user of the cost: "This keyword research will cost $0.50. Approve?"
2. If user approves, retry the request (approval flow TBD)
3. If user declines, abort the operation

### Insufficient Balance (402)

Wallet doesn't have enough funds:

```json
{
  "status": 402,
  "error": "Insufficient balance",
  "price": 50,
  "walletBalance": 10,
  "topUpUrl": "/api/wallet/topup"
}
```

**Action:**
1. Inform user: "You need $0.50 but only have $0.10 in your Agent Hub wallet."
2. Direct them to add funds: "Add funds at agent-hub.dev/dashboard"
3. Abort the operation

### Exceeds Per-Transaction Limit (402)

Cost exceeds the user's per-transaction limit:

```json
{
  "status": 402,
  "error": "Exceeds per-transaction limit",
  "price": 200,
  "limit": 100
}
```

**Action:**
1. Inform user: "This operation costs $2.00 but your per-transaction limit is $1.00."
2. Suggest: "You can increase your limit at agent-hub.dev/dashboard"
3. Abort the operation

### Would Exceed Daily Limit (402)

Operation would push spending over daily limit:

```json
{
  "status": 402,
  "error": "Would exceed daily limit",
  "price": 50,
  "spentToday": 980,
  "dailyLimit": 1000
}
```

**Action:**
1. Inform user: "You've spent $9.80 today. This $0.50 operation would exceed your $10.00 daily limit."
2. Suggest: "Try again tomorrow or increase your daily limit."
3. Abort the operation

## Best Practices

### 1. Use maxPrice

Always set `maxPrice` to avoid surprises:

```json
{
  "action": "search",
  "params": { "keyword": "test" },
  "maxPrice": 10
}
```

If the actual price exceeds maxPrice, the request fails immediately without charging.

### 2. Check wallet for expensive operations

Before operations you expect to be costly:

```bash
# Check balance first
curl "https://agent-hub.dev/api/wallet" \
  -H "Authorization: Bearer $TOKEN"
```

### 3. Batch awareness

If doing multiple operations, track cumulative cost:

```
Operation 1: $0.02
Operation 2: $0.05
Operation 3: $0.03
Total: $0.10

"These 3 operations will cost approximately $0.10. Proceed?"
```

### 4. Graceful degradation

If a 402 blocks an operation:
- Explain clearly to user
- Suggest alternatives if available
- Don't retry without user action

## Example Handler

```python
def execute_resource(slug, action, params):
    response = requests.post(
        f"{API_URL}/resources/{slug}/execute",
        headers={"Authorization": f"Bearer {token}"},
        json={"action": action, "params": params, "maxPrice": 100}
    )
    
    if response.status_code == 200:
        return response.json()["result"]
    
    if response.status_code == 402:
        data = response.json()
        
        if data.get("error") == "Insufficient balance":
            raise InsufficientFundsError(
                f"Need ${data['price']/100:.2f}, have ${data['walletBalance']/100:.2f}"
            )
        
        if not data.get("autoApproved"):
            raise ApprovalRequiredError(
                f"Operation costs ${data['price']/100:.2f}, needs approval"
            )
        
        raise PaymentError(data.get("error", "Payment failed"))
    
    response.raise_for_status()
```

## User Communication Templates

### Needs approval
> "This operation will cost $X.XX. Should I proceed?"

### Insufficient balance
> "Your Agent Hub wallet has $X.XX but this costs $Y.YY. Please add funds at agent-hub.dev/dashboard."

### Exceeds limit
> "This costs $X.XX but your limit is $Y.YY. You can adjust limits at agent-hub.dev/dashboard."

### Daily limit reached
> "You've reached your daily spending limit of $X.XX. Try again tomorrow or increase your limit."
