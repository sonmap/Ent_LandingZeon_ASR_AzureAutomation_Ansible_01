# Enterprise Landing Zone ASR Azure Automation Ansible

이 저장소는 `azure-landing-zone_test03`의 Landing Zone 샘플 구조를 기준으로 **주센터(Korea Central)** 와 **DR센터(Japan East)** 를 완전히 분리하고, VM은 **Azure Site Recovery(ASR)** 로 보호하며, 복구 후 처리는 **Azure Automation Runbook + Ansible** 로 자동화하는 설계/구현 템플릿입니다.

## 핵심 설계 원칙

1. 주센터와 DR센터 Landing Zone은 독립 디렉터리로 분리합니다.
2. DR센터는 VM이 붙을 수 있는 Landing Zone, VNet, Subnet, NSG, UDR, Private DNS, AKS, 공통 PaaS 골격을 사전 구성합니다.
3. VM 자체는 DR센터에 미리 만들지 않습니다. ASR이 Failover 시 복구 VM/NIC/Disk를 생성합니다.
4. AKS는 ASR 대상이 아닙니다. DR센터에 별도 AKS를 구성하고 GitOps/Helm/Ansible로 App을 배포합니다.
5. ASR은 별도 `asr/` 영역에서 관리합니다.
6. Failover Runbook은 `runbooks/`와 `ansible/`로 분리하여 자동화합니다.

## Repository Layout

```text
.
├── primary-krc/                 # 주센터 Korea Central Landing Zone
│   ├── 2-environments/
│   ├── 3-networks-hub-and-spoke/
│   └── 5-app-infra/
├── dr-jpe/                      # DR센터 Japan East Landing Zone
│   ├── 2-environments/
│   ├── 3-networks-hub-and-spoke/
│   └── 5-app-infra/
├── asr/                         # ASR 전용 영역
│   ├── terraform/
│   └── scripts/
├── runbooks/azure-automation/    # ASR Recovery Plan 후처리 Runbook
├── ansible/                      # VM/AKS 후처리 자동화
└── docs/                         # 설계/런북/검증 문서
```

## 실행 순서

```bash
# 1. 주센터 Landing Zone 구성
cd primary-krc
# 원본 azure-landing-zone_test03 Terraform stage 구조를 이 디렉터리 기준으로 실행

# 2. DR센터 Landing Zone 구성
cd ../dr-jpe
# DR센터는 VM 생성 비활성화, AKS/PaaS/Network 중심 구성

# 3. ASR 구성
cd ../asr/terraform
terraform init
terraform plan -out=tfplan
terraform apply tfplan

# 4. VM 보호 등록 / Test Failover / 실제 Failover
cd ../scripts
./asr_enable_vm_protection.sh
./run_test_failover.sh
./run_unplanned_failover.sh

# 5. 복구 후 자동화
cd ../../ansible
ansible-playbook -i inventory/dr.ini playbooks/dr-post-failover.yml
ansible-playbook -i inventory/dr.ini playbooks/aks-dr-scale-up.yml
```

## 문서

- [DR Architecture](docs/architecture.md)
- [Failover Runbook](docs/failover-runbook.md)
- [Automation Strategy](docs/automation-strategy.md)
- [Validation Checklist](docs/validation-checklist.md)

## 주의

이 저장소는 기업형 DR 설계를 위한 템플릿입니다. 실제 운영 적용 전에는 구독 ID, Tenant ID, IP 대역, VM ID, Vault 이름, Recovery Plan 이름, DNS Zone, Front Door, AWX URL 등 환경값을 반드시 수정해야 합니다.
