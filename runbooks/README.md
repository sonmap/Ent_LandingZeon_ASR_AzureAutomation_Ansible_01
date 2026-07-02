# Runbooks

이 디렉터리는 ASR Recovery Plan과 연계되는 Azure Automation Runbook을 관리합니다.

## 구성

```text
runbooks/
└── azure-automation/
    ├── post-failover-config.ps1
    └── invoke-ansible-awx.ps1
```

## Runbook 역할

| Runbook | 역할 |
|---|---|
| `post-failover-config.ps1` | ASR Failover 후 복구 VM, NSG, LB, DNS, Extension, RBAC 후처리 |
| `invoke-ansible-awx.ps1` | Azure Automation에서 AWX/Ansible Automation Platform Job Template 호출 |

## ASR Recovery Plan 연동 방식

```text
ASR Recovery Plan
  Group 1: Core VM Failover
    Post Action: post-failover-config.ps1

  Group 2: App VM Failover
    Post Action: post-failover-config.ps1

  Group 3: AKS / Traffic 전환 준비
    Manual Action: DR 전환 승인
    Post Action: invoke-ansible-awx.ps1
```

## Recovery Plan Context

ASR Recovery Plan에서 Azure Automation Runbook을 호출하면 `RecoveryPlanContext`를 전달받을 수 있습니다. 이 Context를 이용해 다음 정보를 처리합니다.

- Recovery Plan 이름
- Failover Type
- Failover Direction
- Group ID
- VM Map
- 복구 대상 VM 목록

## 권장 자동화 범위

| 자동화 항목 | 권장 위치 |
|---|---|
| VM 복구 순서 제어 | ASR Recovery Plan |
| NIC / NSG / LB / DNS 처리 | Azure Automation |
| VM Extension / RBAC 재적용 | Azure Automation |
| OS Agent 설치 | Ansible |
| App Service 기동 | Ansible |
| Health Check | Ansible |
| AKS App Scale-up | Ansible / GitOps |
| Front Door / DNS 전환 | Azure Automation 또는 수동 승인 후 CLI |

## 운영 순서

1. Recovery Plan 실행
2. ASR이 VM 복구
3. Recovery Plan Post Action으로 `post-failover-config.ps1` 호출
4. Runbook에서 Azure 리소스 후처리
5. 필요 시 `invoke-ansible-awx.ps1`로 Ansible Job 호출
6. Ansible에서 OS/App/AKS 후처리
7. 정상성 확인 후 Traffic 전환

## 운영 전 준비

```text
[ ] Automation Account Managed Identity 활성화
[ ] Managed Identity에 필요한 RBAC 부여
[ ] Runbook Import 및 Publish
[ ] Az PowerShell Module 준비
[ ] AWX Token Key Vault 저장
[ ] Recovery Plan Post Action에 Runbook 연결
[ ] Test Failover로 Context 수신 확인
```

## 필요한 RBAC 예시

| 대상 | 권한 |
|---|---|
| Target Resource Group | Contributor |
| Network Resource Group | Network Contributor |
| Private DNS Zone RG | Private DNS Zone Contributor |
| VM Resource Group | Virtual Machine Contributor |
| Automation Account | Automation Contributor |
| Key Vault | Key Vault Secrets User |

## 보안 주의

- AWX Token은 Runbook 코드에 직접 넣지 않습니다.
- Key Vault 또는 Automation Variable/Connection을 사용합니다.
- 실제 Failover 전환 명령은 승인 단계 뒤에 실행합니다.
- Test Failover와 실제 Failover Runbook을 분리하는 것을 권장합니다.
