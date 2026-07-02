# Runbooks

이 디렉터리는 DR 운영 자동화 자료를 관리합니다. Azure Automation용 PowerShell Runbook과 Linux 운영자, CI/CD, AWX에서 실행할 수 있는 Bash Runbook을 함께 제공합니다.

## 구성

```text
runbooks/
├── README.md
├── azure-automation/
│   ├── post-failover-config.ps1
│   └── invoke-ansible-awx.ps1
└── bash/
    ├── env/dr.env.example
    ├── lib/common.sh
    ├── 00-precheck.sh
    ├── 10-asr-vault-context.sh
    ├── 20-test-failover.sh
    ├── 30-emergency-cutover-check.sh
    ├── 40-post-failover-network.sh
    ├── 50-post-failover-vm.sh
    ├── 60-aks-dr-scale-up.sh
    ├── 70-traffic-switch-template.sh
    ├── 80-health-check.sh
    └── 90-return-precheck.sh
```

## Bash와 PowerShell 분리 기준

Azure Automation 표준 Runbook은 PowerShell/Python 중심입니다. Bash는 Azure Automation 안에 직접 넣기보다 다음 위치에서 실행하는 방식을 권장합니다.

| 위치 | Bash 역할 |
|---|---|
| Linux Jump VM | 폐쇄망 운영자가 직접 실행 |
| GitHub Actions | 수동 승인 후 실행 |
| Azure DevOps | Manual Approval 후 Bash Task 실행 |
| AWX/Ansible Controller | Job Template에서 Shell Script 호출 |
| Azure Automation | PowerShell/Python Runbook이 Webhook 또는 Hybrid Worker를 통해 간접 호출 |

## Azure Automation Runbook 역할

| Runbook | 역할 |
|---|---|
| `post-failover-config.ps1` | 복구 VM, NSG, LB, DNS, Extension, RBAC 후처리 |
| `invoke-ansible-awx.ps1` | AWX/Ansible Automation Platform Job Template 호출 |

## Bash Runbook 역할

| Script | 역할 |
|---|---|
| `00-precheck.sh` | Azure CLI 로그인, Source VM, DR RG/VNet/Subnet/Vault/AKS 사전 점검 |
| `10-asr-vault-context.sh` | ASR Vault Context 설정, Fabric/Policy 조회 |
| `20-test-failover.sh` | Test Failover 전 네트워크/Recovery Plan 값 검증 |
| `30-emergency-cutover-check.sh` | 전환 전 승인 Ticket, DRY_RUN, Vault Context 확인 |
| `40-post-failover-network.sh` | DR VNet/Subnet/NIC/NSG/UDR/Private DNS 확인 |
| `50-post-failover-vm.sh` | 복구 VM, Disk, Identity, Ansible VM 후처리 확인 |
| `60-aks-dr-scale-up.sh` | DR AKS Credential 획득, Deployment Scale-up, Pod/Service 확인 |
| `70-traffic-switch-template.sh` | Front Door/Traffic Manager/DNS 전환 명령 템플릿 |
| `80-health-check.sh` | 외부 URL, AKS, VM Health Check |
| `90-return-precheck.sh` | 주센터 복귀 전 Primary/DR 상태 점검 |

## Bash 실행 예시

```bash
cd runbooks/bash
cp env/dr.env.example env/dr.env
vi env/dr.env
chmod +x *.sh

./00-precheck.sh
./10-asr-vault-context.sh
./40-post-failover-network.sh
./50-post-failover-vm.sh
DRY_RUN=false ./60-aks-dr-scale-up.sh
./80-health-check.sh
```

## 권장 자동화 범위

| 자동화 항목 | 권장 위치 |
|---|---|
| VM 복구 순서 제어 | ASR Recovery Plan |
| NIC / NSG / LB / DNS 처리 | Azure Automation 또는 Bash |
| VM Extension / RBAC 재적용 | Azure Automation 또는 Ansible |
| OS Agent 설치 | Ansible |
| App Service 기동 | Ansible |
| Health Check | Bash / Ansible |
| AKS App Scale-up | Bash / Ansible / GitOps |
| Front Door / DNS 전환 | Bash 템플릿 또는 승인 후 CLI |

## 운영 전 준비

```text
[ ] Automation Account Managed Identity 활성화
[ ] Managed Identity에 필요한 RBAC 부여
[ ] Bash 실행 서버에 az/kubectl/ansible/jq/curl 설치
[ ] env/dr.env 작성
[ ] AWX Token은 Key Vault 또는 안전한 Secret Store에 저장
[ ] Test Failover로 절차 검증
```

## 보안 주의

- AWX Token은 Runbook 코드에 직접 넣지 않습니다.
- 상태 변경 스크립트는 `DRY_RUN=true` 기본값을 유지합니다.
- 승인 Ticket 없이 전환 작업을 수행하지 않습니다.
- Test Failover와 실제 전환 절차를 분리합니다.
