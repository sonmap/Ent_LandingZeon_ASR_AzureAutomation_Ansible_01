#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/lib/common.sh"

log "Post failover VM check started"
require_env TARGET_RG
az_login_check

log "Recovered VM list"
az vm list -g "$TARGET_RG" --show-details --query "[].{name:name,powerState:powerState,privateIps:privateIps,publicIps:publicIps,location:location}" -o table

mapfile -t VMS < <(az vm list -g "$TARGET_RG" --query "[].name" -o tsv)

for vm in "${VMS[@]}"; do
  log "VM instance view: $vm"
  az vm get-instance-view -g "$TARGET_RG" -n "$vm" --query "{name:name,statuses:instanceView.statuses[].displayStatus}" -o json || true

  log "VM disks: $vm"
  az vm show -g "$TARGET_RG" -n "$vm" --query "{osDisk:storageProfile.osDisk.name,dataDisks:storageProfile.dataDisks[].name}" -o json || true

  log "VM identity: $vm"
  az vm show -g "$TARGET_RG" -n "$vm" --query "identity" -o json || true
done

if [[ -f "${ANSIBLE_INVENTORY:-}" && -f "${ANSIBLE_VM_PLAYBOOK:-}" ]]; then
  log "Run Ansible VM post-check playbook"
  if [[ "${DRY_RUN:-true}" == "true" ]]; then
    ansible-playbook -i "$ANSIBLE_INVENTORY" "$ANSIBLE_VM_PLAYBOOK" --check || true
  else
    ansible-playbook -i "$ANSIBLE_INVENTORY" "$ANSIBLE_VM_PLAYBOOK"
  fi
else
  log "Ansible inventory or playbook not found. Skip Ansible section."
fi

log "Post failover VM check completed"
