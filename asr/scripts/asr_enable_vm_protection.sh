#!/usr/bin/env bash
set -euo pipefail

# VM ASR 보호 등록 템플릿입니다.
# 실제 운영에서는 아래 값을 환경에 맞게 채운 뒤 실행하십시오.

SUBSCRIPTION_ID="${SUBSCRIPTION_ID:-00000000-0000-0000-0000-000000000000}"
VAULT_RG="${VAULT_RG:-rg-land03-asr-jpe}"
VAULT_NAME="${VAULT_NAME:-rsv-land03-krc-to-jpe-001}"
SOURCE_VM_RG="${SOURCE_VM_RG:-rg-land03-dev-workloads}"
SOURCE_VM_NAME="${SOURCE_VM_NAME:-vm-land03-krc-001}"
TARGET_RG="${TARGET_RG:-rg-land03-dr-dev-workloads-jpe}"
TARGET_VNET_ID="${TARGET_VNET_ID:-/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/rg-land03-dr-dev-workloads-jpe/providers/Microsoft.Network/virtualNetworks/vnet-land03-spoke-vm-jpe-001}"
TARGET_SUBNET_NAME="${TARGET_SUBNET_NAME:-snet-vm}"
CACHE_STORAGE_ID="${CACHE_STORAGE_ID:-/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/rg-land03-dev-workloads/providers/Microsoft.Storage/storageAccounts/stland03asrcache001}"

az account set --subscription "$SUBSCRIPTION_ID"

SOURCE_VM_ID=$(az vm show -g "$SOURCE_VM_RG" -n "$SOURCE_VM_NAME" --query id -o tsv)

cat <<INFO
ASR 보호 등록 전 확인:
  Vault: $VAULT_RG / $VAULT_NAME
  Source VM: $SOURCE_VM_ID
  Target RG: $TARGET_RG
  Target VNet: $TARGET_VNET_ID
  Target Subnet: $TARGET_SUBNET_NAME
  Cache Storage: $CACHE_STORAGE_ID
INFO

# 실제 ASR 보호 등록은 환경별 Fabric / Protection Container / Policy / Mapping 이름 조회가 필요합니다.
# Azure Portal 또는 az site-recovery 명령으로 다음 순서로 구성하십시오.
# 1. vault set-context
# 2. replication policy 생성
# 3. fabric/protection-container 조회
# 4. protection-container-mapping 생성
# 5. network-mapping 생성
# 6. protected-item create로 VM 보호 등록

az site-recovery vault set-context \
  --resource-group "$VAULT_RG" \
  --vault-name "$VAULT_NAME"

echo "ASR context configured. Continue with policy/container/network mapping and protected-item create."
