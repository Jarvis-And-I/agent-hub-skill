# API Reference

## Base URL

```
https://agent-hub.dev/api
```

## Authentication

Include your token in the Authorization header:

```
Authorization: Bearer cb_your_token_here
```

## Endpoints

### List Resources

```http
GET /api/resources
GET /api/resources?q=<query>
GET /api/resources?category=<category>
```

**Query Parameters:**
- `q` (optional): Search query
- `category` (optional): Filter by category
- `limit` (optional): Max results (default: 20)
- `offset` (optional): Pagination offset

**Response:**
```json
{
  "resources": [
    {
      "slug": "screenshot",
      "name": "Screenshot API",
      "description": "Capture screenshots of any webpage",
      "category": "web-tools",
      "pricing": { "capture": 2 }
    }
  ],
  "total": 5,
  "limit": 20,
  "offset": 0
}
```

### Get Resource Details

```http
GET /api/resources/<slug>
```

**Response:**
```json
{
  "slug": "screenshot",
  "name": "Screenshot API",
  "description": "Capture screenshots of any webpage",
  "category": "web-tools",
  "pricing": { "capture": 2 },
  "docs": "# Screenshot API\n\n..."
}
```

### Get Resource Documentation

```http
GET /api/resources/<slug>/docs
```

**Response:**
```json
{
  "slug": "screenshot",
  "name": "Screenshot API",
  "docs": "# Screenshot API\n\n## Actions\n\n### capture\n..."
}
```

### Execute Resource

```http
POST /api/resources/<slug>/execute
Content-Type: application/json
Authorization: Bearer <token>

{
  "action": "capture",
  "params": {
    "url": "https://example.com"
  },
  "maxPrice": 10
}
```

**Request Body:**
- `action` (required): The action to perform
- `params` (required): Parameters for the action
- `maxPrice` (optional): Maximum price in cents (fails if actual price exceeds)

**Success Response (200):**
```json
{
  "status": 200,
  "paymentId": "pay_abc123",
  "charged": 2,
  "resource": "screenshot",
  "action": "capture",
  "result": {
    "imageUrl": "https://...",
    "timestamp": "2024-..."
  }
}
```

**Payment Required (402):**
```json
{
  "status": 402,
  "resource": "screenshot",
  "action": "capture",
  "price": 50,
  "walletBalance": 1000,
  "autoApproved": false,
  "reason": "exceeds_auto_approve_limit"
}
```

### Get Wallet

```http
GET /api/wallet
Authorization: Bearer <token>
```

**Response:**
```json
{
  "balance": 1000,
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

### Update Wallet Limits

```http
PUT /api/wallet
Authorization: Bearer <token>
Content-Type: application/json

{
  "dailyLimit": 2000,
  "perTxLimit": 200,
  "autoApproveMax": 100
}
```

### Add Funds

```http
POST /api/wallet/topup
Authorization: Bearer <token>
Content-Type: application/json

{
  "amount": 2000,
  "method": "card"
}
```

**Response:**
```json
{
  "checkoutUrl": "https://checkout.stripe.com/..."
}
```

### Transaction History

```http
GET /api/wallet/transactions
GET /api/wallet/transactions?limit=10&offset=0
Authorization: Bearer <token>
```

**Response:**
```json
{
  "transactions": [
    {
      "id": "tx_123",
      "resource": "screenshot",
      "action": "capture",
      "amount": 2,
      "status": "completed",
      "createdAt": "2024-..."
    }
  ],
  "total": 50
}
```

## Error Responses

### 400 Bad Request
```json
{
  "error": "Invalid request body",
  "details": [...]
}
```

### 401 Unauthorized
```json
{
  "error": "Not authenticated"
}
```

### 402 Payment Required
```json
{
  "status": 402,
  "error": "Insufficient balance",
  "price": 50,
  "walletBalance": 10
}
```

### 404 Not Found
```json
{
  "error": "Resource not found"
}
```

### 500 Internal Server Error
```json
{
  "error": "Resource execution failed",
  "message": "..."
}
```
