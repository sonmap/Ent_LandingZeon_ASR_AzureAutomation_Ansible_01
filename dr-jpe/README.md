# DR Landing Zone - Japan East

이 디렉터리는 DR센터 Landing Zone을 위한 독립 실행 영역입니다. 주센터와 동일한 논리 구조를 가지지만 Region, 이름, CIDR, VM 생성 정책을 분리합니다.

## 기준

- Region: `japaneast`
- Prefix: `land03-dr`
- 목적: DR Landing Zone, ASR Target Network, DR AKS, DR PaaS 골격
- VM: 평상시 생성하지 않음. ASR Failover 시 생성.

## 실행 순서

```bash
cd dr-jpe/2-environments
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
```

## 설계 원칙

- DR센터는 운영 VM을 사전 생성하지 않습니다.
- ASR Target Resource Group, Target VNet/Subnet은 사전 구성합니다.
- AKS는 ASR 대상이 아니므로 DR AKS를 별도 구성합니다.
- DB/Storage/Key Vault/Secret은 별도 복제 전략이 필요합니다.
