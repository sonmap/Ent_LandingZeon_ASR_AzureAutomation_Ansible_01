# DR Runbook RACI

## 목적

DR 전환 시 역할과 책임을 명확히 하여 승인 지연, 중복 작업, 누락 작업을 방지합니다.

## 역할 정의

| 역할 | 설명 |
|---|---|
| DR Commander | DR 전환 총괄, 승인, 의사결정 |
| Incident Manager | 장애 상황 기록, ITSM 관리, 회의 진행 |
| Azure Operator | ASR, VM, Vault, Automation Account 운영 |
| Network Operator | NSG, UDR, DNS, Front Door, LB 전환 |
| VM Operator | OS, Agent, Extension, 서비스 기동 확인 |
| AKS Operator | DR AKS, Pod, Service, Ingress, Helm/GitOps 운영 |
| DB/Storage Owner | 데이터 정합성, DB/Storage 복제 확인 |
| Application Owner | 업무 정상성 검증, 사용자 오픈 승인 |
| Security Owner | 접근 권한, RBAC, 보안 Agent, 감사 확인 |
| Communication Owner | 사용자 공지, 경영진/관계자 보고 |

## RACI Matrix

R = Responsible, A = Accountable, C = Consulted, I = Informed

| 단계 | DR Commander | Incident | Azure | Network | VM | AKS | DB/Storage | App | Security | Comm |
|---|---|---|---|---|---|---|---|---|---|---|
| 장애 선언 | A | R | C | C | C | C | C | C | I | R |
| DR 전환 승인 | A | R | C | C | C | C | C | C | C | I |
| Recovery Plan 실행 | I | C | A/R | C | C | I | I | I | I | I |
| VM Failover 확인 | I | C | A/R | C | R | I | C | C | C | I |
| Extension/RBAC 재적용 | I | C | A/R | I | R | I | I | I | C | I |
| NSG/LB/DNS 확인 | I | C | C | A/R | C | C | I | C | C | I |
| AKS DR Scale-up | I | C | C | C | I | A/R | C | C | C | I |
| 데이터 정합성 확인 | I | C | I | I | C | C | A/R | C | C | I |
| 트래픽 전환 | A | R | C | A/R | C | C | C | C | C | R |
| 애플리케이션 검증 | I | C | C | C | C | C | C | A/R | C | I |
| 사용자 오픈 | A | R | I | I | I | I | I | A/R | I | R |
| Failback 승인 | A | R | C | C | C | C | C | C | C | I |

## 승인 기준

| 승인 항목 | 승인자 | 조건 |
|---|---|---|
| DR 전환 시작 | DR Commander | 주센터 복구 예상 시간이 RTO 초과 |
| ASR Recovery Plan 실행 | DR Commander + Azure Operator | 대상 VM 및 Recovery Point 확인 |
| 트래픽 전환 | DR Commander + App Owner + Network Operator | DR 서비스 Health Check 성공 |
| 사용자 오픈 | DR Commander + App Owner | 업무 검증 완료 |
| Failback 시작 | DR Commander + App Owner + DB/Storage Owner | 주센터 안정화 및 데이터 정합성 확인 |

## 상황 기록 양식

| 시간 | 이벤트 | 담당자 | 결과 | 다음 조치 |
|---|---|---|---|---|
|  | 장애 감지 |  |  |  |
|  | DR 전환 승인 |  |  |  |
|  | Recovery Plan 실행 |  |  |  |
|  | VM 복구 완료 |  |  |  |
|  | AKS 활성화 |  |  |  |
|  | Traffic 전환 |  |  |  |
|  | 사용자 오픈 |  |  |  |
