#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/lib/common.sh"

log "DR precheck started"

require_cmd az
require_cmd jq
require_cmd curl
require_cmd kubectl
require_cmd ansible-playbook

require_env SUBSCRIPTION_ID
require_env SOURCE_VM_RG
require_env SOURCE_VM_NAME
require_env TARGET_RG
require_env TARGET_VNET
require_env TARGET_SUBNET
require_env TEST_FAILOVER_SUBNET
require_env VAULT_RG
require_env VAULT_NAME
require_env DR_AKS_RG
require_env DR_AKS_NAME

az_login_check

log "Input summary"
print_kv "Source VM RG" "$SOURCE_VM_RG"
print_kv "Source VM" "$SOURCE_VM_NAME"
print_kv "Target RG" "$TARGET_RG"
print_kv "Target VNet" "$TARGET_VNET"
print_kv "Target Subnet" "$TARGET_SUBNET"
print_kv "Test Subnet" "$TEST_FAILOVER_SUBNET"
print_kv "Vault" "$VAULT_RG/$VAULT_NAME"
print_kv "DR AKS" "$DR_AKS_RG/$DR_AKS_NAME"

log "Check source VM"
az vm show -g "$SOURCE_VM_RG" -n "$SOURCE_VM_NAME" --query "{name:name,location:location,provisioningState:provisioningState,powerState:powerState}" -o table || fail "source VM not found"

log "Check DR resource group"
az group show -n "$TARGET_RG" --query "{name:name,location:location}" -o table || fail "target RG not found"

log "Check DR VNet"
az network vnet show -g "$TARGET_RG" -n "$TARGET_VNET" --query "{name:name,location:location,addressSpace:addressSpace.addressPrefixes}" -o json || fail "target VNet not found"

log "Check target subnet"
az network vnet subnet show -g "$TARGET_RG" --vnet-name "$TARGET_VNET" -n "$TARGET_SUBNET" --query "{name:name,addressPrefix:addressPrefix,addressPrefixes:addressPrefixes}" -o json || fail "target subnet not found"

log "Check test failover subnet"
az network vnet subnet show -g "$TARGET_RG" --vnet-name "$TARGET_VNET" -n "$TEST_FAILOVER_SUBNET" --query "{name:name,addressPrefix:addressPrefix,addressPrefixes:addressPrefixes}" -o json || fail "test failover subnet not found"

log "Check Recovery Services Vault"
az backup vault show -g "$VAULT_RG" -n "$VAULT_NAME" --query "{name:name,location:location}" -o table || log "Vault may be Recovery Services Vault for ASR; check Portal if az backup vault show does not find it."

log "Check DR AKS"
az aks show -g "$DR_AKS_RG" -n "$DR_AKS_NAME" --query "{name:name,location:location,privateFqdn:privateFqdn,provisioningState:provisioningState}" -o table || fail "DR AKS not found"

log "DR precheck completed"
