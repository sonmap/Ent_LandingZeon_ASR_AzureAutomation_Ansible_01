#!/usr/bin/env bash
set -euo pipefail

SUBSCRIPTION_ID="${SUBSCRIPTION_ID:-00000000-0000-0000-0000-000000000000}"
VAULT_RG="${VAULT_RG:-rg-land03-asr-jpe}"
VAULT_NAME="${VAULT_NAME:-rsv-land03-krc-to-jpe-001}"
RECOVERY_PLAN_NAME="${RECOVERY_PLAN_NAME:-rp-land03-krc-to-jpe}"
TEST_NETWORK_ID="${TEST_NETWORK_ID:-/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/rg-land03-dr-dev-workloads-jpe/providers/Microsoft.Network/virtualNetworks/vnet-land03-spoke-vm-jpe-001}"

az account set --subscription "$SUBSCRIPTION_ID"
az site-recovery vault set-context -g "$VAULT_RG" --vault-name "$VAULT_NAME"

cat <<INFO
Test Failover 실행 전 확인:
  Recovery Plan: $RECOVERY_PLAN_NAME
  Test Network: $TEST_NETWORK_ID
INFO

# 예시 명령입니다. 실제 파라미터는 az site-recovery recovery-plan failover 명령 도움말과 환경별 Recovery Plan ID를 기준으로 조정하십시오.
# az site-recovery recovery-plan failover \
#   --recovery-plan-name "$RECOVERY_PLAN_NAME" \
#   --failover-direction PrimaryToRecovery \
#   --failover-type TestFailover \
#   --network-id "$TEST_NETWORK_ID"

echo "Review the command comments, then execute Test Failover in the approved change window."
