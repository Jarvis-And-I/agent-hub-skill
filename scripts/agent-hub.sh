#!/bin/bash
# Agent Hub CLI - Main wrapper script
# Usage: agent-hub.sh <command> [args...]

set -e

CONFIG_DIR="${HOME}/.clawdbot/skills/agent-hub"
CONFIG_FILE="${CONFIG_DIR}/config.json"
API_URL="${AGENT_HUB_URL:-https://agent-hub.dev/api}"

# Load config
load_config() {
  if [ -f "$CONFIG_FILE" ]; then
    TOKEN=$(jq -r '.token // empty' "$CONFIG_FILE")
    API_URL=$(jq -r '.apiUrl // "https://agent-hub.dev/api"' "$CONFIG_FILE")
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
  require_auth
  local slug="$1"
  local action="$2"
  local params="$3"
  
  curl -s -X POST "${API_URL}/resources/${slug}/execute" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${TOKEN}" \
    -d "{\"action\": \"${action}\", \"params\": ${params:-{}}}"
}

cmd_wallet() {
  require_auth
  curl -s "${API_URL}/wallet" \
    -H "Authorization: Bearer ${TOKEN}" | jq '.'
}

cmd_help() {
  cat << 'EOF'
Agent Hub CLI

Usage: agent-hub.sh <command> [args...]

Commands:
  list                          List all available resources
  search <query>                Search for resources
  docs <slug>                   Show documentation for a resource
  execute <slug> <action> [params]  Execute a resource action
  wallet                        Check wallet balance and limits

Examples:
  agent-hub.sh list
  agent-hub.sh search screenshot
  agent-hub.sh docs screenshot
  agent-hub.sh execute screenshot capture '{"url": "https://example.com"}'
  agent-hub.sh wallet

Environment:
  AGENT_HUB_URL     API base URL (default: https://agent-hub.dev/api)

Config file: ~/.clawdbot/skills/agent-hub/config.json
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
