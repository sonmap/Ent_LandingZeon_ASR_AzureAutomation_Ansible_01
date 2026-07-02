# Validation Checklist

## DR센터 Landing Zone 검증

- [ ] DR Resource Group 생성 확인
- [ ] DR Hub VNet 생성 확인
- [ ] DR VM Target Spoke VNet 생성 확인
- [ ] DR AKS Spoke VNet 생성 확인
- [ ] Subnet CIDR 충돌 없음
- [ ] NSG 규칙 주센터와 동일 또는 DR 정책 반영
- [ ] UDR / Route Table 정상
- [ ] Private DNS Zone / Link 정상
- [ ] DR Key Vault 생성
- [ ] Log Analytics / Monitoring 연계

## ASR 검증

- [ ] Recovery Services Vault 생성
- [ ] Replication Policy 생성
- [ ] Cache Storage Account 생성
- [ ] Target Resource Group 지정
- [ ] Target VNet/Subnet 지정
- [ ] VM Protected Item 등록
- [ ] Initial Replication 완료
- [ ] Test Failover 성공
- [ ] Test Failover Cleanup 완료
- [ ] Recovery Plan 실행 순서 확인

## Failover 후 검증

- [ ] 복구 VM 생성 확인
- [ ] OS Disk / Data Disk 연결 확인
- [ ] Private IP 확인
- [ ] VM Agent / Monitoring Agent 재설치
- [ ] VM Extension 재적용
- [ ] RBAC Role Assignment 확인
- [ ] NSG / Route / Internal LB 확인
- [ ] Private DNS Record 확인
- [ ] App Service Health Check 성공

## AKS DR 검증

- [ ] DR AKS Cluster 생성
- [ ] Node Pool Scale-up 가능
- [ ] Namespace 동기화
- [ ] Helm/Manifest 배포 가능
- [ ] Image Pull 가능
- [ ] Secret / Config 적용
- [ ] Ingress / Service 정상
- [ ] Pod Replica 증가 확인

## Traffic 전환 검증

- [ ] Front Door / Traffic Manager Health Probe 정상
- [ ] DNS TTL 확인
- [ ] DR Endpoint 라우팅 확인
- [ ] 사용자 접속 확인
- [ ] 운영 공지 / 사용자 오픈 승인
