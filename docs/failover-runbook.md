# VM/AKS DR Failover Runbook

## 1. 목적

장애 발생 시 주센터(Korea Central)에서 DR센터(Japan East)로 서비스를 전환하고, ASR VM 복구와 AKS DR App 활성화를 표준 절차에 따라 수행합니다.

이 Runbook은 다음 범위를 포함합니다.

- 장애 판단 및 DR 전환 승인
- ASR Recovery Plan 실행
- VM Failover 및 복구 VM 검증
- VM Extension / Agent / RBAC 재적용
- Internal Load Balancer / NSG / Route / DNS 확인
- AKS DR App Scale-up
- Front Door / DNS / Traffic 전환
- 애플리케이션 정상성 확인
- 사용자 오픈
- Failback / Reprotect 준비

---

## 2. 적용 범위

| 구분 | 적용 여부 | 설명 |
|---|---:|---|
| Azure VM | 적용 | ASR로 OS/Data Disk 복제 후 DR센터에서 복구 VM 생성 |
| AKS | 적용 | ASR 대상 아님. DR센터 AKS를 별도 활성화 |
| Storage Account | 부분 적용 | ASR 대상 아님. 별도 복제/DR Storage 필요 |
| Key Vault | 부분 적용 | 별도 DR Key Vault 및 Secret 동기화 필요 |
| DB | 부분 적용 | DB Native Replication 또는 별도 복구 절차 필요 |
| Front Door / DNS | 적용 | 트래픽 전환 절차 필요 |
| Azure RBAC | 별도 조치 | ASR로 자동 복제되지 않으므로 Runbook에서 재적용 |
| VM Extension / Agent | 별도 조치 | Failover 후 재설치/재적용 필요 |

---

## 3. 사전 준비 조건

### 3.1 Azure 리소스 준비

| 항목 | 필요 상태 | 확인 명령 예시 |
|---|---|---|
| DR Resource Group | 생성 완료 | `az group show -n rg-land03-dr-dev-workloads-jpe` |
| DR VNet/Subnet | 생성 완료 | `az network vnet show -g rg-land03-dr-dev-workloads-jpe -n vnet-land03-spoke-vm-jpe-001` |
| Test Failover Subnet | 생성 완료 | `az network vnet subnet show ... -n snet-test-failover` |
| Recovery Services Vault | 생성 완료 | `az backup vault list -o table` |
| ASR Replication Policy | 생성 완료 | Portal 또는 `az site-recovery` 조회 |
| Cache Storage Account | 생성 완료 | `az storage account show -g rg-land03-dev-workloads -n <cache>` |
| Automation Account | 생성 완료 | `az automation account show -g rg-land03-asr-jpe -n aa-land03-dr-runbook-jpe` |
| DR AKS | 생성 완료 | `az aks show -g rg-land03-dr-dev-workloads-jpe -n aks-land03-jpe-001` |

### 3.2 운영 권한 준비

| 역할 | 필요한 권한 |
|---|---|
| DR Commander | 장애 선언, DR 전환 승인 |
| Azure Operator | ASR Recovery Plan 실행, Azure 리소스 확인 |
| Network Operator | NSG, UDR, DNS, Front Door 전환 |
| VM Operator | 복구 VM, Agent, Extension, OS 서비스 확인 |
| AKS Operator | DR AKS Scale-up, Pod/Service/Ingress 확인 |
| Application Owner | 업무 정상성 확인 및 사용자 오픈 승인 |

### 3.3 필수 변수

| 변수 | 예시 |
|---|---|
| `SUBSCRIPTION_ID` | `<SUBSCRIPTION_ID>` |
| `SOURCE_VM_RG` | `rg-land03-dev-workloads` |
| `SOURCE_VM_NAME` | `vm-land03-krc-001` |
| `TARGET_RG` | `rg-land03-dr-dev-workloads-jpe` |
| `TARGET_VNET` | `vnet-land03-spoke-vm-jpe-001` |
| `TARGET_SUBNET` | `snet-vm` |
| `TEST_FAILOVER_SUBNET` | `snet-test-failover` |
| `VAULT_RG` | `rg-land03-asr-jpe` |
| `VAULT_NAME` | `rsv-land03-krc-to-jpe-001` |
| `RECOVERY_PLAN_NAME` | `rp-land03-krc-to-jpe` |
| `DR_AKS_NAME` | `aks-land03-jpe-001` |
| `DR_AKS_RG` | `rg-land03-dr-dev-workloads-jpe` |

---

## 4. 장애 등급 및 DR 전환 판단

| 등급 | 상황 | 조치 |
|---|---|---|
| SEV-1 | 주센터 전체 리전 장애, 핵심 업무 중단 | DR 전환 검토 즉시 시작 |
| SEV-2 | 주요 서비스 다수 장애, 복구 예상 시간 초과 | DR 전환 승인 회의 |
| SEV-3 | 단일 VM/서비스 장애 | 일반 복구 우선, DR 전환 보류 |
| SEV-4 | 영향 경미 | 모니터링 및 일반 조치 |

### DR 전환 기준

다음 중 하나 이상이면 DR 전환을 검토합니다.

- 주센터 복구 예상 시간이 RTO를 초과함
- 주센터 네트워크 또는 핵심 플랫폼 복구가 불가능함
- 업무 영향이 크고 사용자 접속이 장시간 중단됨
- 보안/운영 책임자가 DR 전환을 승인함

---

## 5. 실제 Failover Runbook

### Step 1. 장애 선언

**담당:** DR Commander, Application Owner  
**도구:** ITSM, Teams/메일, 모니터링 시스템

작업:

1. 장애 발생 시각 기록
2. 장애 범위 확인
3. 영향 업무 확인
4. RTO/RPO 기준 확인
5. DR 전환 여부 승인
6. 사용자/관계자 공지

체크:

```text
[ ] 장애 발생 시각 기록
[ ] 영향 시스템 목록 작성
[ ] DR 전환 승인자 확인
[ ] 사용자 공지 초안 작성
[ ] Change / ITSM Ticket 생성
```

---

### Step 2. ASR Recovery Plan 실행

**담당:** Azure Operator  
**도구:** Azure Portal, Azure CLI, ASR Recovery Plan

작업:

1. Recovery Services Vault 접속
2. Recovery Plan 선택
3. Failover Direction 확인: `PrimaryToRecovery`
4. Recovery Point 선택
5. Recovery Plan 실행

명령 예시:

```bash
export SUBSCRIPTION_ID="<SUBSCRIPTION_ID>"
export VAULT_RG="rg-land03-asr-jpe"
export VAULT_NAME="rsv-land03-krc-to-jpe-001"
export RECOVERY_PLAN_NAME="rp-land03-krc-to-jpe"

az account set --subscription "$SUBSCRIPTION_ID"
az site-recovery vault set-context \
  --resource-group "$VAULT_RG" \
  --vault-name "$VAULT_NAME"
```

체크:

```text
[ ] Recovery Plan 이름 확인
[ ] 대상 VM Group 확인
[ ] Recovery Point 확인
[ ] 실행 승인 확인
[ ] ASR Job 상태 모니터링 시작
```

---

### Step 3. VM Failover 확인

**담당:** Azure Operator, VM Operator

작업:

1. DR센터 Target RG에 복구 VM 생성 확인
2. OS Disk / Data Disk 연결 확인
3. NIC / Private IP 확인
4. Boot Diagnostics 확인
5. VM Power State 확인

명령 예시:

```bash
az vm list -g rg-land03-dr-dev-workloads-jpe -o table
az vm get-instance-view -g rg-land03-dr-dev-workloads-jpe -n <recovered-vm-name> -o table
az network nic list -g rg-land03-dr-dev-workloads-jpe -o table
```

체크:

```text
[ ] 복구 VM 생성됨
[ ] VM Running 상태
[ ] OS Disk 연결 정상
[ ] Data Disk 연결 정상
[ ] NIC 생성 정상
[ ] Private IP 확인
```

---

### Step 4. VM Extension / Agent / RBAC 재적용

**담당:** Azure Operator, VM Operator  
**도구:** Azure Automation Runbook, Ansible

작업:

1. VM Agent 상태 확인
2. Monitoring Agent / Dependency Agent / 보안 Agent 재설치
3. VM Extension 재적용
4. Azure RBAC Role Assignment 재적용
5. Managed Identity 필요 여부 확인

Azure Automation Runbook:

```text
runbooks/azure-automation/post-failover-config.ps1
```

Ansible Playbook:

```bash
cd ansible
ansible-playbook -i inventory/dr.ini playbooks/dr-post-failover.yml
```

체크:

```text
[ ] VM Agent 정상
[ ] Monitoring Agent 정상
[ ] Security Agent 정상
[ ] VM Extension 재적용 완료
[ ] RBAC Role Assignment 확인
[ ] OS 서비스 자동기동 설정 확인
```

---

### Step 5. Internal LB / NSG / UDR / DNS 확인

**담당:** Network Operator

작업:

1. NSG Inbound/Outbound 규칙 확인
2. UDR / Route Table 확인
3. Internal Load Balancer Backend Pool 연결 확인
4. Private DNS Record 확인
5. VM 간 통신 확인
6. AKS/VM/DB 경로 확인

명령 예시:

```bash
az network nsg list -g rg-land03-dr-dev-workloads-jpe -o table
az network route-table list -g rg-land03-dr-dev-workloads-jpe -o table
az network private-dns zone list -g rg-land03-dr-hub-network-jpe -o table
```

체크:

```text
[ ] NSG 규칙 정상
[ ] UDR 경로 정상
[ ] 내부 LB Backend Pool 정상
[ ] Private DNS 해석 정상
[ ] VM → DB 통신 정상
[ ] VM → AKS 통신 정상
```

---

### Step 6. AKS DR App Scale-up

**담당:** AKS Operator, Application Owner

AKS는 ASR로 복구하지 않습니다. DR센터 AKS를 사전에 만들어 두고, 장애 시 App Replica를 증가시켜 활성화합니다.

작업:

1. DR AKS Credential 획득
2. Node Pool 상태 확인
3. Namespace 확인
4. Deployment Replica 증가
5. Image Pull 확인
6. Service / Ingress 확인

명령 예시:

```bash
az aks get-credentials \
  -g rg-land03-dr-dev-workloads-jpe \
  -n aks-land03-jpe-001 \
  --overwrite-existing

kubectl get nodes -o wide
kubectl get ns
kubectl get pods,svc,ingress -A
kubectl scale deployment myapp -n prod --replicas=3
kubectl rollout status deployment/myapp -n prod --timeout=300s
```

Ansible:

```bash
cd ansible
ansible-playbook -i inventory/dr.ini playbooks/aks-dr-scale-up.yml
```

체크:

```text
[ ] DR AKS API 접근 가능
[ ] Node Ready
[ ] Namespace 존재
[ ] Pod Running
[ ] Service Endpoint 정상
[ ] Ingress 정상
[ ] Image Pull 성공
```

---

### Step 7. Front Door / DNS / Traffic 전환

**담당:** Network Operator, Application Owner

작업:

1. DR Endpoint Health Check 확인
2. Front Door Origin Group 또는 Traffic Manager Endpoint 변경
3. DNS Record 변경 또는 Weight 변경
4. TTL 확인
5. 외부 사용자 경로 확인

체크:

```text
[ ] DR Endpoint Health Probe 정상
[ ] Front Door Origin 활성화
[ ] DNS Record DR센터로 전환
[ ] TTL 반영 대기
[ ] 외부 접속 성공
```

---

### Step 8. 애플리케이션 정상성 확인

**담당:** Application Owner, VM Operator, AKS Operator

확인 항목:

| 항목 | 확인 방법 |
|---|---|
| Web 화면 | 브라우저 접속 |
| API | `curl /health`, Postman |
| DB 연결 | App 로그, DB Listener 확인 |
| 로그인 | 테스트 계정 |
| 배치 | 샘플 Job 실행 |
| 로그 | App/Container/VM 로그 |
| 모니터링 | Azure Monitor / Log Analytics |

체크:

```text
[ ] Web 정상
[ ] API 정상
[ ] 로그인 정상
[ ] DB 연결 정상
[ ] AKS Pod 로그 정상
[ ] VM App 로그 정상
[ ] 모니터링 알람 없음
```

---

### Step 9. 사용자 오픈

**담당:** DR Commander, Application Owner

작업:

1. 최종 정상성 결과 취합
2. 사용자 오픈 승인
3. 업무 재개 공지
4. 사후 집중 모니터링 시작
5. 장애 보고서 작성 시작

체크:

```text
[ ] 사용자 오픈 승인
[ ] 업무 재개 공지
[ ] 모니터링 대시보드 확인
[ ] 30분/1시간/2시간 단위 상태 점검
[ ] 장애 보고서 작성 시작
```

---

## 6. Test Failover Runbook

Test Failover는 운영망과 분리된 테스트 네트워크에서 수행합니다.

절차:

1. Test Failover Network 확인
2. Recovery Plan Test Failover 실행
3. Test VM 생성 확인
4. Test VM Boot 확인
5. App 기동 여부 확인
6. 운영망 영향 없음 확인
7. Test Failover Cleanup 실행

체크:

```text
[ ] Test Failover Network 지정
[ ] 운영망과 IP 충돌 없음
[ ] Test VM 생성
[ ] Test VM 접속 가능
[ ] App 기동 확인
[ ] Cleanup 완료
[ ] ASR Replication 정상 복귀
```

---

## 7. Failback / Reprotect 개요

주센터 복구 후 바로 원복하지 않습니다. 다음 조건을 확인한 뒤 Failback을 준비합니다.

1. 주센터 Landing Zone 정상
2. 주센터 VM Target Network 정상
3. 데이터 정합성 확인
4. DR센터 변경 데이터 보존
5. Reprotect 가능 상태 확인
6. Planned Failover 일정 승인

Failback 절차는 `docs/failback-runbook.md`를 따릅니다.

---

## 8. Runbook 산출물

| 산출물 | 위치 |
|---|---|
| 전체 Failover 절차 | `docs/failover-runbook.md` |
| Test Failover 절차 | `docs/test-failover-runbook.md` |
| Failback 절차 | `docs/failback-runbook.md` |
| 운영 역할/RACI | `docs/runbook-raci.md` |
| Azure Automation 설명 | `runbooks/README.md` |
| Post-Failover Runbook | `runbooks/azure-automation/post-failover-config.ps1` |
| AWX 호출 Runbook | `runbooks/azure-automation/invoke-ansible-awx.ps1` |
| VM 후처리 Playbook | `ansible/playbooks/dr-post-failover.yml` |
| AKS Scale-up Playbook | `ansible/playbooks/aks-dr-scale-up.yml` |

---

## 9. 운영 유의사항

- AKS는 ASR 대상이 아닙니다.
- VM Extension / RBAC는 Target VM으로 자동 복제되지 않으므로 별도 조치가 필요합니다.
- DNS / Front Door 전환 절차는 사전에 문서화해야 합니다.
- 실제 장애 전 Test Failover는 필수입니다.
- 실제 Failover 명령은 승인 없이는 실행하지 않습니다.
- DR센터에서 사용자 오픈 후에는 주센터 변경 작업을 중지합니다.
