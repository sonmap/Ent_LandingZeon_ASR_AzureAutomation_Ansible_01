# Failback / Reprotect Runbook

## 1. 목적

DR센터로 Failover 후 주센터가 복구되었을 때, 서비스를 안전하게 주센터로 되돌리기 위한 절차입니다.

Failback은 단순히 VM을 다시 켜는 작업이 아닙니다. DR센터에서 운영 중 발생한 데이터 변경분을 주센터로 되돌리고, 정합성 확인 후 Planned Failover를 수행해야 합니다.

## 2. Failback 기본 원칙

- 주센터 복구 직후 즉시 원복하지 않습니다.
- DR센터가 현재 운영 기준이므로 주센터에 임의 변경을 금지합니다.
- Reprotect 가능 상태를 먼저 확인합니다.
- 데이터 정합성 검증 후 Planned Failover를 수행합니다.
- 사용자 트래픽 전환은 별도 승인 후 수행합니다.

## 3. 사전 조건

| 항목 | 조건 |
|---|---|
| 주센터 Region | Azure 서비스 정상 |
| 주센터 Landing Zone | RG/VNet/Subnet/NSG/UDR/DNS 정상 |
| DR센터 VM | 운영 중이며 서비스 정상 |
| ASR 상태 | Commit 완료, Reprotect 가능 |
| 데이터 | DR센터 기준 최신 데이터 확인 |
| 트래픽 | 현재 DR센터로 유입 중 |
| 승인 | Failback Change 승인 완료 |

## 4. Failback 절차

### Step 1. 주센터 복구 상태 확인

```bash
az group show -n rg-land03-dev-workloads
az network vnet show -g rg-land03-dev-workloads -n vnet-land03-spoke-vm-krc-001
az network vnet subnet list -g rg-land03-dev-workloads --vnet-name vnet-land03-spoke-vm-krc-001 -o table
```

체크:

```text
[ ] 주센터 RG 정상
[ ] 주센터 VNet/Subnet 정상
[ ] NSG/UDR 정상
[ ] Private DNS 정상
[ ] Quota 여유 확인
```

### Step 2. DR센터 운영 데이터 확인

```text
[ ] DB 변경분 확인
[ ] 파일/Storage 변경분 확인
[ ] App 로그 확인
[ ] 배치 처리 결과 확인
[ ] 사용자 트랜잭션 정상 완료 확인
```

### Step 3. ASR Commit 상태 확인

Failover 이후 DR센터 운영 상태가 확정되면 Commit을 수행해야 합니다. Commit 이후에는 해당 Failover가 확정됩니다.

```text
[ ] Failover Commit 완료
[ ] ASR Job 성공
[ ] Recovery Plan 상태 정상
```

### Step 4. Reprotect 수행

DR센터 VM을 기준으로 주센터 방향으로 다시 복제를 설정합니다.

```text
Direction: RecoveryToPrimary
Source: DR센터 복구 VM
Target: 주센터 Resource Group / VNet / Subnet
```

체크:

```text
[ ] Reprotect 실행
[ ] Initial Replication 시작
[ ] Replication 완료
[ ] Recovery Point 생성 확인
```

### Step 5. Planned Failover 준비

Planned Failover는 데이터 손실을 최소화하기 위해 서비스 중단 시간에 맞춰 수행합니다.

```text
[ ] 사용자 공지
[ ] 업무 중단 시간 승인
[ ] 배치 작업 중지
[ ] App Read-only 전환 검토
[ ] DR센터 최신 데이터 확인
```

### Step 6. 주센터 방향 Planned Failover

```text
Direction: RecoveryToPrimary
Type: Planned Failover
```

작업:

1. DR센터 App 중지 또는 Read-only 전환
2. Planned Failover 실행
3. 주센터 VM 생성/기동 확인
4. 주센터 Agent/Extension/RBAC 확인
5. 주센터 App 기동
6. 주센터 내부 통신 확인

### Step 7. Traffic 원복

```text
[ ] 주센터 Health Check 정상
[ ] Front Door Origin 주센터 활성화
[ ] DNS 주센터로 전환
[ ] 외부 접속 확인
[ ] 사용자 오픈 공지
```

### Step 8. DR센터 재보호 상태 확인

Failback 후에는 다시 주센터 → DR센터 방향으로 보호해야 합니다.

```text
[ ] 주센터가 Primary 역할 복귀
[ ] DR센터가 Recovery 역할 복귀
[ ] ASR 방향 PrimaryToRecovery 재설정
[ ] Test Failover 계획 수립
```

## 5. 실패 시 Rollback

| 실패 단계 | 조치 |
|---|---|
| 주센터 VM 생성 실패 | DR센터 운영 유지, Planned Failover 중단 |
| 주센터 App 기동 실패 | DR센터로 Traffic 유지, 원인 분석 |
| DNS 전환 실패 | Front Door / Traffic Manager 수동 확인 |
| 데이터 불일치 | Failback 중단, DB/Storage 담당자 확인 |
| Reprotect 실패 | ASR Job 로그 확인, Vault/Policy/Mapping 확인 |

## 6. 완료 보고 양식

| 항목 | 내용 |
|---|---|
| Failback 일시 |  |
| 담당자 |  |
| 승인 Ticket |  |
| DR 운영 기간 |  |
| 데이터 검증 결과 |  |
| Planned Failover 결과 |  |
| Traffic 원복 결과 |  |
| 사후 이슈 |  |
| 재보호 상태 |  |
