#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/lib/common.sh"

log "ASR test validation started"
require_env RECOVERY_PLAN_NAME
require_env TARGET_RG
require_env TARGET_VNET
require_env TEST_FAILOVER_SUBNET
az_login_check

TEST_VNET_ID=$(az network vnet show -g "$TARGET_RG" -n "$TARGET_VNET" --query id -o tsv)
TEST_SUBNET_ID=$(az network vnet subnet show -g "$TARGET_RG" --vnet-name "$TARGET_VNET" -n "$TEST_FAILOVER_SUBNET" --query id -o tsv)

print_kv "Recovery Plan" "$RECOVERY_PLAN_NAME"
print_kv "Test VNet" "$TEST_VNET_ID"
print_kv "Test Subnet" "$TEST_SUBNET_ID"
print_kv "DRY_RUN" "${DRY_RUN:-true}"

az vm list -g "$TARGET_RG" --query "[].{name:name,location:location}" -o table || true

log "This script prepares and validates the test network values."
log "Run the approved ASR test operation from Portal or paste your tested az site-recovery command below after validation."

log "ASR test validation completed"
