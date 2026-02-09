#!/bin/bash
# Connect to Agent Hub using a linking code
# Generates a keypair for request signing
# Usage: agent-hub-connect.sh <code>

set -e

CONFIG_DIR="${HOME}/.clawdbot/skills/agent-hub"
CONFIG_FILE="${CONFIG_DIR}/config.json"
PRIVATE_KEY_FILE="${CONFIG_DIR}/private.pem"
PUBLIC_KEY_FILE="${CONFIG_DIR}/public.pem"
API_URL="${AGENT_HUB_URL:-https://agent-hub.dev/api}"

CODE="$1"

if [ -z "$CODE" ]; then
  echo "Usage: agent-hub-connect.sh <linking-code>"
  echo ""
  echo "Get a linking code from: https://agent-hub.dev/dashboard"
  exit 1
fi

# Create config directory
mkdir -p "$CONFIG_DIR"

# Generate keypair if not exists
if [ ! -f "$PRIVATE_KEY_FILE" ]; then
  echo "Generating keypair for request signing..."
  openssl ecparam -genkey -name prime256v1 -noout -out "$PRIVATE_KEY_FILE" 2>/dev/null
  openssl ec -in "$PRIVATE_KEY_FILE" -pubout -out "$PUBLIC_KEY_FILE" 2>/dev/null
  chmod 600 "$PRIVATE_KEY_FILE"
  echo "✓ Keypair generated"
fi

# Read public key (remove headers and newlines for JSON)
PUBLIC_KEY=$(cat "$PUBLIC_KEY_FILE")

# Generate a unique clawdbot ID if not set
CLAWDBOT_ID="${CLAWDBOT_ID:-$(hostname)-$(date +%s)}"

echo "Connecting to Agent Hub..."

RESPONSE=$(curl -s -X POST "${API_URL}/auth/connect" \
  -H "Content-Type: application/json" \
  -d "{
    \"code\": \"${CODE}\",
    \"clawdbotId\": \"${CLAWDBOT_ID}\",
    \"publicKey\": $(echo "$PUBLIC_KEY" | jq -Rs .),
    \"hostname\": \"$(hostname)\"
  }")

# Check for error
ERROR=$(echo "$RESPONSE" | jq -r '.error // empty')
if [ -n "$ERROR" ]; then
  echo "Error: $ERROR"
  exit 1
fi

# Extract token
TOKEN=$(echo "$RESPONSE" | jq -r '.token // empty')
if [ -z "$TOKEN" ]; then
  echo "Error: No token received"
  echo "Response: $RESPONSE"
  exit 1
fi

# Save config
cat > "$CONFIG_FILE" << EOF
{
  "token": "${TOKEN}",
  "apiUrl": "${API_URL}",
  "clawdbotId": "${CLAWDBOT_ID}",
  "privateKeyFile": "${PRIVATE_KEY_FILE}",
  "publicKeyFile": "${PUBLIC_KEY_FILE}",
  "connectedAt": "$(date -Iseconds)"
}
EOF

chmod 600 "$CONFIG_FILE"

echo "✓ Successfully connected to Agent Hub!"
echo ""
echo "Config saved to: $CONFIG_FILE"
echo "Private key: $PRIVATE_KEY_FILE (keep secret!)"
echo "Clawdbot ID: $CLAWDBOT_ID"
echo ""
echo "All requests will be cryptographically signed."
echo "Even if your token is stolen, attackers can't use it without your private key."
echo ""
echo "Test with: agent-hub.sh list"
