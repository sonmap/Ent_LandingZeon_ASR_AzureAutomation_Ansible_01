#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/lib/common.sh"

log "AKS DR scale-up started"
require_env DR_AKS_RG
require_env DR_AKS_NAME
require_env AKS_NAMESPACE
require_env AKS_DEPLOYMENT
require_env AKS_REPLICAS
az_login_check
require_cmd kubectl

log "Get DR AKS credentials"
az aks get-credentials \
  --resource-group "$DR_AKS_RG" \
  --name "$DR_AKS_NAME" \
  --overwrite-existing

log "AKS node status"
kubectl get nodes -o wide

log "Namespace status"
kubectl get namespace "$AKS_NAMESPACE" || fail "namespace not found: $AKS_NAMESPACE"

log "Current deployment status"
kubectl get deployment "$AKS_DEPLOYMENT" -n "$AKS_NAMESPACE" -o wide

if [[ "${DRY_RUN:-true}" == "true" ]]; then
  log "DRY_RUN=true. Showing scale command only."
  echo "kubectl scale deployment $AKS_DEPLOYMENT -n $AKS_NAMESPACE --replicas=$AKS_REPLICAS"
else
  log "Scale deployment"
  kubectl scale deployment "$AKS_DEPLOYMENT" -n "$AKS_NAMESPACE" --replicas="$AKS_REPLICAS"
  kubectl rollout status deployment/"$AKS_DEPLOYMENT" -n "$AKS_NAMESPACE" --timeout=300s
fi

log "Pods, services, ingress"
kubectl get pods,svc,ingress -n "$AKS_NAMESPACE" -o wide

if [[ -f "${ANSIBLE_INVENTORY:-}" && -f "${ANSIBLE_AKS_PLAYBOOK:-}" ]]; then
  log "Optional Ansible AKS playbook"
  if [[ "${DRY_RUN:-true}" == "true" ]]; then
    ansible-playbook -i "$ANSIBLE_INVENTORY" "$ANSIBLE_AKS_PLAYBOOK" --check || true
  else
    ansible-playbook -i "$ANSIBLE_INVENTORY" "$ANSIBLE_AKS_PLAYBOOK"
  fi
fi

log "AKS DR scale-up completed"
