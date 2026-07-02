#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/lib/common.sh"

log "DR health validation started"
require_env APP_HEALTH_URL
az_login_check

log "External application health validation"
HTTP_CODE=$(curl -k -sS -o /tmp/dr-health.out -w "%{http_code}" "$APP_HEALTH_URL" || true)
print_kv "URL" "$APP_HEALTH_URL"
print_kv "HTTP_CODE" "$HTTP_CODE"

if [[ "$HTTP_CODE" =~ ^(200|301|302|401|403)$ ]]; then
  log "External health validation accepted"
else
  log "External health validation unexpected. Review response body."
  cat /tmp/dr-health.out || true
fi

if [[ -n "${DR_AKS_RG:-}" && -n "${DR_AKS_NAME:-}" ]]; then
  log "AKS status"
  az aks get-credentials -g "$DR_AKS_RG" -n "$DR_AKS_NAME" --overwrite-existing >/dev/null 2>&1 || true
  kubectl get nodes -o wide || true
  kubectl get pods,svc,ingress -n "${AKS_NAMESPACE:-prod}" -o wide || true
fi

if [[ -n "${TARGET_RG:-}" ]]; then
  log "VM status"
  az vm list -g "$TARGET_RG" --show-details --query "[].{name:name,powerState:powerState,privateIps:privateIps}" -o table || true
fi

log "DR health validation completed"
