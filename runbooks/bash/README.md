# Bash Runbooks

## 목적

Azure Automation Runbook을 PowerShell 중심으로만 두지 않고, Linux 운영자가 바로 실행할 수 있는 Bash 기반 DR Runbook을 제공합니다.

> 중요: Azure Automation의 표준 Runbook 타입은 PowerShell / Python 중심입니다. Bash는 Azure Automation Runbook 타입으로 직접 관리하기보다 Linux Control Host, GitHub Actions, Azure DevOps, AWX/Ansible Controller, 또는 Hybrid Worker에서 실행하는 운영 스크립트로 사용하는 것을 권장합니다.

## 구성

```text
runbooks/bash/
├── README.md
├── env/
│   └── dr.env.example
├── lib/
│   └── common.sh
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

## 실행 전 준비

```bash
cd runbooks/bash
cp env/dr.env.example env/dr.env
vi env/dr.env
chmod +x *.sh
```

필수 도구:

```bash
az version
kubectl version --client
ansible --version
jq --version
curl --version
```

Azure 로그인:

```bash
az login
az account set --subscription "$SUBSCRIPTION_ID"
```

## 권장 실행 순서

### 1. 사전 점검

```bash
./00-precheck.sh
```

### 2. ASR Vault Context 설정

```bash
./10-asr-vault-context.sh
```

### 3. Test Failover 준비/검증

```bash
./20-test-failover.sh
```

### 4. 실제 장애 전환 전 승인 가드

실제 장애 시에만 실행합니다. 기본값은 Dry Run입니다.

```bash
DRY_RUN=true ./30-emergency-cutover-check.sh
DRY_RUN=false ./30-emergency-cutover-check.sh
```

### 5. Failover 후 네트워크 확인

```bash
./40-post-failover-network.sh
```

### 6. Failover 후 VM 확인

```bash
./50-post-failover-vm.sh
```

### 7. DR AKS App Scale-up

```bash
DRY_RUN=true ./60-aks-dr-scale-up.sh
DRY_RUN=false ./60-aks-dr-scale-up.sh
```

### 8. Traffic 전환 템플릿

```bash
DRY_RUN=true ./70-traffic-switch-template.sh
```

### 9. Health Check

```bash
./80-health-check.sh
```

### 10. 주센터 복귀 사전 점검

```bash
./90-return-precheck.sh
```

## 자동화 위치

| 위치 | Bash 사용 방식 |
|---|---|
| 운영자 노트북 | 수동 DR Runbook 실행 |
| Jump VM | 폐쇄망 운영 자동화 |
| GitHub Actions | 승인 후 수동 workflow_dispatch |
| Azure DevOps | Manual approval 후 Bash task |
| AWX/Ansible | shell/command module로 Bash 호출 |
| Azure Automation | PowerShell/Python Runbook에서 Webhook 또는 Hybrid Worker를 통해 간접 호출 |

## 안전 장치

- 상태 변경 가능 스크립트는 `DRY_RUN=true`가 기본입니다.
- 실제 실행 전 `APPROVAL_TICKET` 값을 요구합니다.
- 실제 실행 전 승인 문구 입력을 요구합니다.
- ASR 실제 실행 명령은 환경별 Recovery Plan/Protected Item 확인 후 붙여 넣도록 템플릿화했습니다.
