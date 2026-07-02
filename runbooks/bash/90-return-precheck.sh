#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/lib/common.sh"

log "Return-to-primary precheck started"
require_env SOURCE_VM_RG
require_env TARGET_RG
require_env SOURCE_AKS_RG
require_env SOURCE_AKS_NAME
require_env DR_AKS_RG
require_env DR_AKS_NAME
az_login_check

log "Primary RG status"
az group show -n "$SOURCE_VM_RG" --query "{name:name,location:location,provisioningState:properties.provisioningState}" -o table || true

log "DR RG status"
az group show -n "$TARGET_RG" --query "{name:name,location:location,provisioningState:properties.provisioningState}" -o table || true

log "Primary VM list"
az vm list -g "$SOURCE_VM_RG" --show-details --query "[].{name:name,powerState:powerState,privateIps:privateIps}" -o table || true

log "DR VM list"
az vm list -g "$TARGET_RG" --show-details --query "[].{name:name,powerState:powerState,privateIps:privateIps}" -o table || true

log "Primary AKS status"
az aks show -g "$SOURCE_AKS_RG" -n "$SOURCE_AKS_NAME" --query "{name:name,location:location,provisioningState:provisioningState,privateFqdn:privateFqdn}" -o table || true

log "DR AKS status"
az aks show -g "$DR_AKS_RG" -n "$DR_AKS_NAME" --query "{name:name,location:location,provisioningState:provisioningState,privateFqdn:privateFqdn}" -o table || true

cat <<'CHECKLIST'
Return approval checklist:
[ ] Primary region services stable
[ ] Primary Landing Zone stable
[ ] Data consistency approved
[ ] DR-side changed data protected
[ ] Planned downtime approved
[ ] Traffic rollback procedure approved
CHECKLIST

log "Return-to-primary precheck completed"
