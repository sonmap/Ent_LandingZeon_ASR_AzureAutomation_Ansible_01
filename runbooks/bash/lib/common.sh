#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUNBOOK_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="${ENV_FILE:-$RUNBOOK_DIR/env/dr.env}"

if [[ -f "$ENV_FILE" ]]; then
  # shellcheck disable=SC1090
  source "$ENV_FILE"
else
  echo "ERROR: env file not found: $ENV_FILE"
  echo "Copy env/dr.env.example to env/dr.env and edit values."
  exit 1
fi

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || fail "required command not found: $1"
}

require_env() {
  local name="$1"
  [[ -n "${!name:-}" ]] || fail "required env missing: $name"
}

run_cmd() {
  log "+ $*"
  if [[ "${DRY_RUN:-true}" == "true" ]]; then
    log "DRY_RUN=true, skip execution"
  else
    "$@"
  fi
}

confirm_actual_dr() {
  require_env APPROVAL_TICKET
  if [[ "${APPROVAL_TICKET}" == "CHANGE-000000" ]]; then
    fail "APPROVAL_TICKET is not set to a real change ticket"
  fi
  echo "This action can affect DR operations. Ticket: $APPROVAL_TICKET"
  read -r -p "Type DR-APPROVED to continue: " answer
  [[ "$answer" == "DR-APPROVED" ]] || fail "approval phrase mismatch"
}

az_login_check() {
  require_cmd az
  require_env SUBSCRIPTION_ID
  az account show >/dev/null 2>&1 || fail "Azure CLI is not logged in. Run az login."
  az account set --subscription "$SUBSCRIPTION_ID"
  log "Azure subscription set: $SUBSCRIPTION_ID"
}

print_kv() {
  printf '%-32s %s\n' "$1" "$2"
}
