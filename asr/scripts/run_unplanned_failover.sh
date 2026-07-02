#!/usr/bin/env bash
set -euo pipefail

SUBSCRIPTION_ID="${SUBSCRIPTION_ID:-00000000-0000-0000-0000-000000000000}"
VAULT_RG="${VAULT_RG:-rg-land03-asr-jpe}"
VAULT_NAME="${VAULT_NAME:-rsv-land03-krc-to-jpe-001}"
RECOVERY_PLAN_NAME="${RECOVERY_PLAN_NAME:-rp-land03-krc-to-jpe}"

az account set --subscription "$SUBSCRIPTION_ID"
az site-recovery vault set-context -g "$VAULT_RG" --vault-name "$VAULT_NAME"

cat <<INFO
실제 장애 Failover 실행 전 확인:
  1. 장애 선언 및 승인 완료
  2. 주센터 복구 가능성 판단 완료
  3. 사용자 공지 완료
  4. DNS / Front Door 전환 권한 확인
  5. Recovery Plan: $RECOVERY_PLAN_NAME
INFO

read -r -p "정말 실제 Failover를 실행하시겠습니까? YES 입력: " CONFIRM
if [[ "$CONFIRM" != "YES" ]]; then
  echo "Cancelled."
  exit 1
fi

# 실제 명령은 환경별 Recovery Plan ID와 Azure CLI 버전에 맞게 조정하십시오.
# az site-recovery recovery-plan unplanned-failover \
#   --recovery-plan-name "$RECOVERY_PLAN_NAME" \
#   --failover-direction PrimaryToRecovery \
#   --source-site-operations NotRequired

echo "Failover command is intentionally commented. Enable after DR approval and validation."
