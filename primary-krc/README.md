# Primary Landing Zone - Korea Central

이 디렉터리는 주센터 Landing Zone을 위한 독립 실행 영역입니다. 원본 `azure-landing-zone_test03`의 CSV 기반 구성을 주센터 기준으로 분리했습니다.

## 기준

- Region: `koreacentral`
- Prefix: `land03`
- 목적: 운영 Landing Zone, 운영 VM, 운영 AKS, 운영 AI/PaaS 샘플

## 실행 순서

```bash
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
```

## 주의

- `<SUBSCRIPTION_ID>`와 `<ADMIN_PUBLIC_IP>`는 실제 값으로 변경해야 합니다.
- 운영 VM은 주센터에서만 생성합니다.
- DR센터의 VM은 ASR Failover 시 생성합니다.
