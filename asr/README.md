# ASR - Azure Site Recovery

이 영역은 주센터 VM을 DR센터로 보호하기 위한 ASR 전용 영역입니다. Landing Zone과 분리하여 독립적으로 운영합니다.

## 대상

- Source Region: `koreacentral`
- Target Region: `japaneast`
- Source VM: `vm-land03-krc-001`
- Target RG: `rg-land03-dr-dev-workloads-jpe`
- Target VNet/Subnet: `vnet-land03-spoke-vm-jpe-001 / snet-vm`
- Test Failover Network: `snet-test-failover`

## ASR 포함 범위

- VM OS Disk / Data Disk 복제
- Failover 시 Target VM 생성
- Recovery Plan 기반 복구 순서 수행
- Test Failover 지원

## ASR 제외 / 별도 고려

- Landing Zone 자체 복제 아님
- AKS / PaaS 별도 DR 설계 필요
- VM Extension / RBAC 별도 처리 필요
- DNS / LB / Front Door 전환 절차 필요

## 실행

```bash
cd asr/terraform
terraform init
terraform plan -out=tfplan
terraform apply tfplan

cd ../scripts
./asr_enable_vm_protection.sh
./run_test_failover.sh
./run_unplanned_failover.sh
```
