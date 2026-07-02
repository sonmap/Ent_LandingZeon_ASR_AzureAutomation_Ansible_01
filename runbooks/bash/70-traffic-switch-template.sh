#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/lib/common.sh"

log "Traffic switch template started"
require_env APPROVAL_TICKET
az_login_check

print_kv "Front Door RG" "${FRONTDOOR_RG:-not-set}"
print_kv "Front Door Profile" "${FRONTDOOR_PROFILE:-not-set}"
print_kv "Endpoint" "${FRONTDOOR_ENDPOINT:-not-set}"
print_kv "Origin Group" "${FRONTDOOR_ORIGIN_GROUP:-not-set}"
print_kv "DR Origin" "${FRONTDOOR_DR_ORIGIN:-not-set}"
print_kv "DRY_RUN" "${DRY_RUN:-true}"

log "Health probe should be green before traffic switch."
log "Use the following command templates only after adapting to your Front Door SKU and object names."

cat <<'COMMANDS'
# Azure Front Door Standard/Premium example template:
# az afd origin update \
#   --resource-group "$FRONTDOOR_RG" \
#   --profile-name "$FRONTDOOR_PROFILE" \
#   --origin-group-name "$FRONTDOOR_ORIGIN_GROUP" \
#   --origin-name "$FRONTDOOR_DR_ORIGIN" \
#   --enabled-state Enabled

# Traffic Manager example template:
# az network traffic-manager endpoint update \
#   --resource-group <rg> \
#   --profile-name <profile> \
#   --name <dr-endpoint> \
#   --type azureEndpoints \
#   --endpoint-status Enabled

# DNS record example template:
# az network dns record-set cname set-record \
#   --resource-group <dns-rg> \
#   --zone-name <zone> \
#   --record-set-name <record> \
#   --cname <dr-endpoint-fqdn>
COMMANDS

if [[ "${DRY_RUN:-true}" == "true" ]]; then
  log "DRY_RUN=true. No traffic object changed."
else
  confirm_actual_dr
  log "Place the validated traffic switch command here after customer-specific Front Door/DNS design is confirmed."
fi

log "Traffic switch template completed"
