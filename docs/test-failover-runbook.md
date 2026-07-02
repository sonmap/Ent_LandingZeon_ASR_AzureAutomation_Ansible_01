# Test Failover Runbook

## 1. 목적

운영 서비스에 영향을 주지 않고 ASR 복구 가능성을 검증합니다. Test Failover는 운영망과 분리된 Test Failover Network에서 수행합니다.

## 2. 원칙

- 운영 Subnet이 아닌 `snet-test-failover` 사용
- 운영 DNS / Front Door / Traffic Manager 전환 금지
- 테스트 VM에서 외부 사용자 트래픽 수신 금지
- 검증 후 반드시 Cleanup 수행

## 3. 사전 확인

| 항목 | 확인 내용 |
|---|---|
| ASR Replication | Protected Item 상태 정상 |
| Recovery Point | 최신 Recovery Point 존재 |
| Test Network | `snet-test-failover` 존재 |
| IP 충돌 | 운영망과 분리 확인 |
| 권한 | Vault / VM / Network 조회 권한 |
| 접속 방법 | Bastion, VPN, Jump VM 등 테스트 접속 경로 |

## 4. 실행 절차

### Step 1. Test Failover 승인

```text
[ ] Change Ticket 생성
[ ] 테스트 대상 VM 확인
[ ] 테스트 시간 승인
[ ] 테스트 담당자 지정
```

### Step 2. Recovery Services Vault Context 설정

```bash
export SUBSCRIPTION_ID="<SUBSCRIPTION_ID>"
export VAULT_RG="rg-land03-asr-jpe"
export VAULT_NAME="rsv-land03-krc-to-jpe-001"

az account set --subscription "$SUBSCRIPTION_ID"
az site-recovery vault set-context \
  --resource-group "$VAULT_RG" \
  --vault-name "$VAULT_NAME"
```

### Step 3. Test Failover 실행

```bash
cd asr/scripts
./run_test_failover.sh
```

실제 명령은 환경별 Recovery Plan / Protected Item 이름 확인 후 주석을 해제합니다.

### Step 4. Test VM 확인

```bash
az vm list -g rg-land03-dr-dev-workloads-jpe -o table
az network nic list -g rg-land03-dr-dev-workloads-jpe -o table
```

체크:

```text
[ ] Test VM 생성됨
[ ] Test VM Running
[ ] Test NIC 생성
[ ] Test Subnet 연결
[ ] 운영 Subnet에 연결되지 않음
```

### Step 5. OS / App 확인

```bash
ssh azureuser@<test-vm-private-ip>
hostname
ip addr
systemctl status <app-service>
curl -I http://127.0.0.1/
```

체크:

```text
[ ] OS 부팅 정상
[ ] Data Disk Mount 확인
[ ] App Service 기동 확인
[ ] Local Health Check 정상
[ ] Agent 상태 확인
```

### Step 6. AKS DR 연계 테스트

AKS는 ASR 대상이 아니므로 Test Failover와 별개로 DR AKS 배포 상태를 확인합니다.

```bash
az aks get-credentials \
  -g rg-land03-dr-dev-workloads-jpe \
  -n aks-land03-jpe-001 \
  --overwrite-existing

kubectl get nodes
kubectl get pods,svc,ingress -A
```

### Step 7. Cleanup

Test Failover 검증이 끝나면 반드시 Cleanup합니다.

체크:

```text
[ ] Test Failover Cleanup 실행
[ ] Test VM 삭제 확인
[ ] Test NIC 삭제 확인
[ ] Test Disk 삭제 확인
[ ] ASR Replication 정상 상태 복귀
[ ] 결과 보고서 작성
```

## 5. 결과 기록 양식

| 항목 | 결과 |
|---|---|
| 테스트 일시 |  |
| 대상 VM |  |
| Recovery Point |  |
| Test Network |  |
| VM Boot 결과 |  |
| App Health 결과 |  |
| AKS DR 확인 |  |
| Cleanup 결과 |  |
| 이슈 |  |
| 조치 계획 |  |

## 6. 실패 시 조치

| 증상 | 확인 |
|---|---|
| Test VM 생성 실패 | Vault Job, Target RG 권한, Quota |
| VM 부팅 실패 | Boot Diagnostics, OS Disk 상태 |
| NIC 연결 실패 | Target Subnet, IP 충돌 |
| App 기동 실패 | Data Disk Mount, 환경변수, Secret |
| Cleanup 실패 | ASR Job 상태, 잔여 리소스 수동 삭제 |
