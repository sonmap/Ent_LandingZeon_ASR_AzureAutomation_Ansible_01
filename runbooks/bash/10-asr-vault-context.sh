#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/lib/common.sh"

log "ASR vault context setup started"
require_env VAULT_RG
require_env VAULT_NAME
az_login_check

log "Set ASR vault context"
az site-recovery vault set-context \
  --resource-group "$VAULT_RG" \
  --vault-name "$VAULT_NAME"

log "List ASR fabrics if available"
az site-recovery fabric list -o table || log "fabric list failed. Confirm Site Recovery extension and vault context."

log "List ASR replication policies if available"
az site-recovery policy list -o table || log "policy list failed. Confirm Site Recovery extension and vault context."

log "ASR vault context setup completed"
