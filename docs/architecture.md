# DR Architecture

## 목표

주센터와 DR센터를 독립적으로 구성하고, VM은 ASR로 보호하며, AKS는 별도 DR 클러스터로 운영합니다.

## 전체 구조

```text
주센터 Korea Central
  Primary Landing Zone
  Hub VNet / VM Spoke / AKS Spoke / Private DNS / NSG / UDR
  운영 VM
  운영 AKS
  운영 Storage / Key Vault / ACR / DB
        │
        │ VM Disk Replication: ASR
        │ Image/Secret/Data Sync: 서비스별 복제
        ▼
DR센터 Japan East
  DR Landing Zone
  Hub VNet / VM Target Spoke / AKS Spoke / Private DNS / NSG / UDR
  ASR Failover 시 복구 VM 생성
  DR AKS 사전 구성
  DR Storage / DR Key Vault / DR ACR / DR DB
```

## 주센터 / DR센터 구성 비교

| 영역 | 주센터 | DR센터 | 방식 |
|---|---|---|---|
| Landing Zone | 생성 | 동일 구조 생성 | Terraform |
| Resource Group | 운영 RG | DR RG | Terraform |
| Hub VNet | `koreacentral` | `japaneast` | Terraform |
| VM Spoke | 운영 VM Subnet | ASR Target Subnet | Terraform |
| AKS Spoke | 운영 AKS | DR AKS | Terraform/GitOps |
| NSG / UDR | 운영 정책 | 동일 정책 또는 DR 정책 | Terraform |
| Private DNS | 운영 Zone | DR Zone 또는 통합 설계 | Terraform |
| VM | 운영 VM 생성 | 평상시 미생성 | 주센터 Terraform, DR ASR |
| VM OS/Data Disk | 운영 Disk | 복제 Disk/복구지점 | ASR |
| VM Extension/RBAC | 운영 적용 | Failover 후 재적용 | Runbook/Ansible |
| AKS | 운영 Cluster | 별도 DR Cluster | Terraform/GitOps |
| ACR | 운영 ACR | Geo-replication/DR ACR | ACR 기능 |
| DB/Storage | 운영 데이터 | 복제 데이터 | DB/Storage별 복제 |
| Traffic | Primary | 장애 시 Secondary | Front Door/DNS |

## 권장 수준

| 수준 | 설명 | 권장 |
|---|---|---|
| Level 1 | DR RG/VNet/Subnet/Vault만 구성 | 실습 최소 |
| Level 2 | DR Landing Zone 전체 구성 | 기본 권장 |
| Level 3 | DR AKS/PaaS/데이터 복제까지 구성 | 운영 권장 |
| Level 4 | Active-Active | 핵심 서비스 |

본 저장소는 **Level 2 + 일부 Level 3** 기준입니다.
