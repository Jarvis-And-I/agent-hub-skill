#!/bin/bash
# Agent Hub CLI - Main wrapper script with request signing
# Usage: agent-hub.sh <command> [args...]

set -e

CONFIG_DIR="${HOME}/.clawdbot/skills/agent-hub"
CONFIG_FILE="${CONFIG_DIR}/config.json"
API_URL="${AGENT_HUB_URL:-https://agent-hub.dev/api}"

TOKEN=""
PRIVATE_KEY_FILE=""

# Load config
load_config() {
  if [ -f "$CONFIG_FILE" ]; then
    TOKEN=$(jq -r '.token // empty' "$CONFIG_FILE")
    API_URL=$(jq -r '.apiUrl // "https://agent-hub.dev/api"' "$CONFIG_FILE")
    PRIVATE_KEY_FILE=$(jq -r '.privateKeyFile // empty' "$CONFIG_FILE")
  fi
}

# Check if authenticated
require_auth() {
  if [ -z "$TOKEN" ]; then
    echo "Error: Not connected to Agent Hub"
    echo "Run: agent-hub-connect.sh <code>"
    exit 1
  fi
}

# Sign a request and make authenticated call
signed_request() {
  local method="$1"
  local endpoint="$2"
  local body="$3"
  
  require_auth
  
  local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  local body_hash=""
  
  if [ -n "$body" ]; then
    body_hash=$(echo -n "$body" | openssl dgst -sha256 -binary | base64)
  fi
  
  local payload="${timestamp}:${body_hash}"
  local signature=""
  
  if [ -n "$PRIVATE_KEY_FILE" ] && [ -f "$PRIVATE_KEY_FILE" ]; then
    signature=$(echo -n "$payload" | openssl dgst -sha256 -sign "$PRIVATE_KEY_FILE" | base64 | tr -d '\n')
  fi
  
  if [ "$method" = "GET" ]; then
    curl -s "${API_URL}${endpoint}" \
      -H "Authorization: Bearer ${TOKEN}" \
      -H "X-Timestamp: ${timestamp}" \
      -H "X-Body-Hash: ${body_hash}" \
      -H "X-Signature: ${signature}"
  else
    curl -s -X "$method" "${API_URL}${endpoint}" \
      -H "Content-Type: application/json" \
      -H "Authorization: Bearer ${TOKEN}" \
      -H "X-Timestamp: ${timestamp}" \
      -H "X-Body-Hash: ${body_hash}" \
      -H "X-Signature: ${signature}" \
      -d "$body"
  fi
}

# Commands
cmd_list() {
  curl -s "${API_URL}/resources" | jq '.resources[] | {slug, name, pricing}'
}

cmd_search() {
  local query="$1"
  curl -s "${API_URL}/resources?q=${query}" | jq '.resources[] | {slug, name, description, pricing}'
}

cmd_docs() {
  local slug="$1"
  curl -s "${API_URL}/resources/${slug}/docs" | jq -r '.docs'
}

cmd_execute() {
  local slug="$1"
  local action="$2"
  local params="${3:-{}}"
  
  local body="{\"action\": \"${action}\", \"params\": ${params}}"
  signed_request "POST" "/resources/${slug}/execute" "$body"
}

cmd_wallet() {
  signed_request "GET" "/wallet" ""
}

cmd_help() {
  cat << 'EOF'
Agent Hub CLI (with request signing)

Usage: agent-hub.sh <command> [args...]

Commands:
  list                              List all available resources (no auth)
  search <query>                    Search for resources (no auth)
  docs <slug>                       Show documentation (no auth)
  execute <slug> <action> [params]  Execute a resource action (signed)
  wallet                            Check wallet balance (signed)

Examples:
  agent-hub.sh list
  agent-hub.sh search screenshot
  agent-hub.sh docs screenshot
  agent-hub.sh execute screenshot capture '{"url": "https://example.com"}'
  agent-hub.sh wallet

Security:
  All authenticated requests are cryptographically signed.
  Even if your token is stolen, it's useless without your private key.

Environment:
  AGENT_HUB_URL     API base URL (default: https://agent-hub.dev/api)

Config: ~/.clawdbot/skills/agent-hub/
  config.json       Token and settings
  private.pem       Private key (never share!)
  public.pem        Public key (registered with Agent Hub)
EOF
}

# Main
load_config

case "${1:-help}" in
  list)
    cmd_list
    ;;
  search)
    cmd_search "$2"
    ;;
  docs)
    cmd_docs "$2"
    ;;
  execute)
    cmd_execute "$2" "$3" "$4"
    ;;
  wallet)
    cmd_wallet
    ;;
  help|--help|-h)
    cmd_help
    ;;
  *)
    echo "Unknown command: $1"
    cmd_help
    exit 1
    ;;
esac
