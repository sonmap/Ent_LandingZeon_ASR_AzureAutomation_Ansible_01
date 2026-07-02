# Enterprise Landing Zone ASR Azure Automation Ansible

이 저장소는 이미 구축된 `azure-landing-zone_test03` 주센터 환경을 기준으로 **DR센터(Japan East)** 를 별도 Landing Zone으로 구성하고, VM은 **Azure Site Recovery(ASR)** 로 보호하며, 복구 후 처리는 **Azure Automation Runbook + Ansible** 로 자동화하는 실행 템플릿입니다.

## 중요한 정정

초기 버전은 `primary-krc`와 `dr-jpe`에 CSV만 들어 있어 Terraform 실행 엔진이 부족했습니다. 이후 `main.tf`를 추가했으나, 현재는 운영 가독성을 위해 단일 `main.tf`를 제거하고 `00`, `10`, `20`, `30` 번호 체계로 분리했습니다.

```text
CSV = 입력값
00-*.tf = CSV locals / 공통 설정
10-*.tf = data source / 참조 리소스
20-*.tf = 핵심 인프라 리소스
30-*.tf = 후속 리소스 / 연결 / PaaS / 자동화
providers.tf / versions.tf / outputs.tf = 공통 Terraform 보조 파일
```

Terraform은 같은 디렉터리의 모든 `*.tf` 파일을 하나로 합쳐 읽기 때문에, `terraform init/plan/apply`는 이전과 동일하게 각 stage 디렉터리에서 수행합니다.

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
│   ├── 2-environments/           # RG 생성
│   ├── 3-networks-hub-and-spoke/ # Hub/Spoke/VNet/Subnet/Private DNS
│   └── 5-app-infra/              # 운영 VM, AKS, Storage, Key Vault, PE
├── dr-jpe/                      # DR센터 Japan East Landing Zone
│   ├── 2-environments/           # DR RG 생성
│   ├── 3-networks-hub-and-spoke/ # DR Hub/Spoke/Target Subnet/Test Subnet
│   └── 5-app-infra/              # DR AKS/PaaS, VM은 create=false
├── asr/                         # ASR 전용 영역
│   ├── terraform/                # Vault, Cache Storage, Automation Account
│   └── scripts/                  # ASR 보호 등록 / Test Failover / Failover
├── runbooks/                    # Runbook 운영 가이드
│   └── azure-automation/         # ASR Recovery Plan 후처리 Runbook
├── ansible/                      # VM/AKS 후처리 자동화
└── docs/                         # 설계/런북/검증 문서
```

## Terraform 파일 분리 기준

### 2-environments

```text
00-csv-locals.tf              # env_config.csv, resource_groups.csv, department_environments.csv 로드
10-resource-groups.tf         # platform/dev Resource Group 생성
20-department-environments.tf # 부서별 환경 Resource Group 생성
```

### 3-networks-hub-and-spoke

```text
00-csv-locals.tf              # network_config, networks, subnets, routes, private_dns_zones CSV 로드
10-data-resource-groups.tf    # 기존 RG data source 조회
20-vnet-subnets.tf            # VNet / Subnet 생성
30-routes-dns-peering.tf      # Route Table / Private DNS / VNet Peering 생성
```

### 5-app-infra

```text
00-csv-locals.tf              # app_config, subnet_refs, vm_workloads, aks_clusters, ai_services CSV 로드
10-data-sources.tf            # Client Config, RG, Subnet data source 조회
20-vm-workloads.tf            # NIC / Linux VM 생성
30-aks-and-paas.tf            # AKS / Storage / Key Vault / Private Endpoint 생성
```

### asr/terraform

```text
00-versions-providers.tf      # Terraform required provider와 AzureRM provider
10-locals.tf                  # ASR 공통 tags
20-recovery-vault-and-cache.tf # ASR RG, Recovery Services Vault, Cache Storage
30-automation-account.tf      # Azure Automation Account
```

## 기존 `azure-landing-zone_test03`가 이미 구축된 경우

이미 주센터가 구축되어 있다면 `primary-krc`를 다시 apply할 필요는 없습니다. 이 저장소는 다음 순서로 사용합니다.

```text
1. 기존 주센터 상태 확인
   - azure-landing-zone_test03에서 생성된 RG/VNet/VM/AKS 확인

2. dr-jpe 적용
   - DR센터 Landing Zone 신규 구성
   - DR VM Target VNet/Subnet/Test Failover Subnet 생성
   - DR AKS/PaaS 골격 생성

3. asr 적용
   - Recovery Services Vault
   - Cache Storage Account
   - Automation Account

4. ASR 보호 등록
   - Source VM을 Target RG/VNet/Subnet으로 보호 등록

5. Test Failover
   - 운영망과 분리된 Test Failover Network에서 검증

6. 실제 장애 시 Recovery Plan 실행
   - Azure Automation Runbook + Ansible 후처리
```

## 신규로 양쪽을 모두 테스트하는 경우

```bash
# 1. 주센터 Landing Zone 테스트 구성
cd primary-krc/2-environments
terraform init
terraform plan -out=tfplan
terraform apply tfplan

cd ../3-networks-hub-and-spoke
terraform init
terraform plan -out=tfplan
terraform apply tfplan

cd ../5-app-infra
terraform init
terraform plan -out=tfplan
terraform apply tfplan

# 2. DR센터 Landing Zone 구성
cd ../../dr-jpe/2-environments
terraform init
terraform plan -out=tfplan
terraform apply tfplan

cd ../3-networks-hub-and-spoke
terraform init
terraform plan -out=tfplan
terraform apply tfplan

cd ../5-app-infra
terraform init
terraform plan -out=tfplan
terraform apply tfplan

# 3. ASR 구성
cd ../../asr/terraform
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

## DR센터 VM 생성 정책

`dr-jpe/5-app-infra/csv/app_config.csv`에서 `enable_vm=false`이고, `dr-jpe/5-app-infra/csv/vm_workloads.csv`에서 `create=false`입니다. 따라서 DR센터에는 평상시 VM을 만들지 않습니다.

```text
DR VM = ASR Failover 시 생성
DR AKS/PaaS/Network = Terraform으로 사전 생성
```

## 문서

- [DR Architecture](docs/architecture.md)
- [Failover Runbook](docs/failover-runbook.md)
- [Test Failover Runbook](docs/test-failover-runbook.md)
- [Failback / Reprotect Runbook](docs/failback-runbook.md)
- [Runbook RACI](docs/runbook-raci.md)
- [Automation Strategy](docs/automation-strategy.md)
- [Validation Checklist](docs/validation-checklist.md)
- [Runbook Operations Guide](runbooks/README.md)

## 주의

실제 운영 적용 전에는 `<SUBSCRIPTION_ID>`, `<ADMIN_PUBLIC_IP>`, VM ID, Vault 이름, Recovery Plan 이름, DNS Zone, Front Door, AWX URL 등 환경값을 반드시 수정해야 합니다.

ASR CLI 스크립트의 실제 Failover 명령은 의도적으로 주석 처리되어 있습니다. Test Failover 검증 후 승인 절차에 따라 주석을 해제하십시오.
