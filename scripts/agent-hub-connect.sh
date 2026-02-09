#!/bin/bash
# Connect to Agent Hub using a linking code
# Usage: agent-hub-connect.sh <code>

set -e

CONFIG_DIR="${HOME}/.clawdbot/skills/agent-hub"
CONFIG_FILE="${CONFIG_DIR}/config.json"
API_URL="${AGENT_HUB_URL:-https://agent-hub.dev/api}"

CODE="$1"

if [ -z "$CODE" ]; then
  echo "Usage: agent-hub-connect.sh <linking-code>"
  echo ""
  echo "Get a linking code from: https://agent-hub.dev/dashboard"
  exit 1
fi

# Generate a unique clawdbot ID if not set
CLAWDBOT_ID="${CLAWDBOT_ID:-$(hostname)-$(date +%s)}"

echo "Connecting to Agent Hub..."

RESPONSE=$(curl -s -X POST "${API_URL}/auth/connect" \
  -H "Content-Type: application/json" \
  -d "{
    \"code\": \"${CODE}\",
    \"clawdbotId\": \"${CLAWDBOT_ID}\",
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
mkdir -p "$CONFIG_DIR"
cat > "$CONFIG_FILE" << EOF
{
  "token": "${TOKEN}",
  "apiUrl": "${API_URL}",
  "clawdbotId": "${CLAWDBOT_ID}",
  "connectedAt": "$(date -Iseconds)"
}
EOF

chmod 600 "$CONFIG_FILE"

echo "✓ Successfully connected to Agent Hub!"
echo ""
echo "Config saved to: $CONFIG_FILE"
echo "Clawdbot ID: $CLAWDBOT_ID"
echo ""
echo "Test with: agent-hub.sh list"
