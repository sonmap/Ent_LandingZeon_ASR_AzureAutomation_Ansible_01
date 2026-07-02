# VM/AKS DR Failover Runbook

## 목적

장애 발생 시 주센터에서 DR센터로 서비스를 전환하고, ASR VM 복구와 AKS DR App 활성화를 순서대로 수행합니다.

## 사전 준비

- Recovery Plan 사전 구성
- Test Failover 정기 검증
- 운영 연락망 / 승인 체계 확정
- DNS / Front Door 전환 권한 확보
- AKS DR 배포 Manifest / Helm Chart 준비
- Ansible Inventory / AWX Job Template 준비

## 실행 절차

| 순서 | 단계 | 자동화 도구 | 상세 작업 |
|---:|---|---|---|
| 1 | 장애 선언 | ITSM/운영자 | 장애 범위 확인, DR 전환 여부 결정, 승인 및 공지 |
| 2 | ASR Recovery Plan 실행 | ASR / Azure Automation | 대상 VM 그룹 선택, 실행 순서 확인, 자동화 스크립트 호출 |
| 3 | VM Failover | ASR | DR센터에 복구 VM 생성, OS/Data Disk 연결, Private IP 할당 |
| 4 | VM Extension / Agent / RBAC 재적용 | Azure Automation + Ansible | 필수 Agent 재설치, VM Extension 점검, 권한 재적용 |
| 5 | Internal LB / NSG / DNS 확인 | Azure Automation + Azure CLI | 내부 LB 연결, NSG 규칙 점검, Private DNS 확인 |
| 6 | AKS DR App Scale-up | GitOps/Ansible/Helm | DR AKS 활성화, App Replica 증가, Ingress/Service 점검 |
| 7 | Front Door / DNS / Traffic 전환 | Azure Automation/CLI | 트래픽 라우팅 변경, Health Check 확인, DR센터 전환 |
| 8 | 애플리케이션 정상성 확인 | Ansible/Monitoring | 화면/API/DB 연계/로그 확인 |
| 9 | 사용자 오픈 | ITSM/운영자 | 업무 재개 공지, 사용자 접속 허용, 사후 모니터링 |

## 실행 흐름

```text
장애 판단
  → Recovery Plan
  → VM 복구
  → 네트워크 확인
  → AKS 활성화
  → 트래픽 전환
  → 정상성 검증
  → 사용자 오픈
```

## 운영 유의사항

- AKS는 ASR 대상이 아닙니다.
- VM Extension / RBAC는 Target VM으로 자동 복제되지 않으므로 별도 조치가 필요합니다.
- DNS / Front Door 전환 절차는 사전에 문서화해야 합니다.
- 실제 장애 전 Test Failover는 필수입니다.
