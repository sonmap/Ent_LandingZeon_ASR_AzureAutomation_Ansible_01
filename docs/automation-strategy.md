# Automation Strategy

## 결론

Ansible 단독보다는 다음 조합을 권장합니다.

```text
Terraform
  → DR Landing Zone / ASR 기본 리소스 사전 구성
ASR Recovery Plan
  → VM Failover 순서 제어
Azure Automation Runbook
  → Azure 리소스 후처리, DNS/LB/RBAC/Extension 조치
Ansible / AWX
  → OS 설정, Agent 설치, App 기동, Health Check, AKS Scale-up
GitOps / Helm
  → AKS 애플리케이션 배포
```

## 역할 분리

| 도구 | 담당 영역 |
|---|---|
| Terraform | 주센터/DR센터 Landing Zone, AKS, Vault, Automation Account |
| ASR Recovery Plan | VM Failover 순서, Group, Manual Action, Runbook 호출 |
| Azure Automation | NIC/NSG/LB/DNS/RBAC/VM Extension 등 Azure API 후처리 |
| Ansible | OS/Agent/App/Health Check/AKS 운영 자동화 |
| GitOps/Helm | AKS App Manifest 동기화 |
| ITSM | 승인, 기록, 공지 |

## 권장 자동화 흐름

```text
운영자 장애 선언
  ↓
ASR Recovery Plan 실행
  ↓
VM Failover
  ↓
Azure Automation Runbook 호출
  ├─ NSG / LB / DNS 확인
  ├─ VM Extension / Agent / RBAC 재적용
  └─ AWX Job Template 호출
        ↓
      Ansible
        ├─ VM OS/App 후처리
        ├─ Health Check
        └─ AKS DR App Scale-up
  ↓
Front Door / DNS 전환
  ↓
사용자 오픈
```

## Ansible 사용 위치

Ansible은 ASR 자체를 대체하는 도구가 아니라, **Failover 이후 후처리 자동화 도구**로 사용하는 것이 안전합니다.

- Linux/Windows Agent 설치
- Tomcat/Nginx/App 서비스 기동
- 설정 파일 수정
- API Health Check
- AKS `kubectl` / `helm` 작업
- 복구 결과 리포트 작성
