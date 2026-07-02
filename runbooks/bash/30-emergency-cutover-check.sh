#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/lib/common.sh"

log "Emergency cutover check started"
require_env RECOVERY_PLAN_NAME
require_env VAULT_RG
require_env VAULT_NAME
require_env APPROVAL_TICKET
az_login_check

print_kv "Vault" "$VAULT_RG/$VAULT_NAME"
print_kv "Recovery Plan" "$RECOVERY_PLAN_NAME"
print_kv "Approval Ticket" "$APPROVAL_TICKET"
print_kv "DRY_RUN" "${DRY_RUN:-true}"

az site-recovery vault set-context \
  --resource-group "$VAULT_RG" \
  --vault-name "$VAULT_NAME"

if [[ "${DRY_RUN:-true}" == "true" ]]; then
  log "DRY_RUN=true. No state changing operation is performed."
  exit 0
fi

confirm_actual_dr

log "Approval guard passed. Use Azure Portal or your validated az site-recovery command for the cutover step."
log "Emergency cutover check completed"
