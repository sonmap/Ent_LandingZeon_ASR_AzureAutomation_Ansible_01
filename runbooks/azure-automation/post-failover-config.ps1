param(
    [Parameter(Mandatory=$false)]
    [object] $RecoveryPlanContext
)

<#
Post-Failover Azure Automation Runbook
역할:
  - ASR Recovery Plan 후처리
  - 복구 VM 목록 확인
  - NSG / LB / DNS / RBAC / Extension 재적용
  - 필요 시 Ansible AWX Job 호출
#>

Write-Output "[DR] Post-failover runbook started."

if ($RecoveryPlanContext) {
    Write-Output "RecoveryPlanContext received."
    $contextJson = $RecoveryPlanContext | ConvertTo-Json -Depth 20
    Write-Output $contextJson
} else {
    Write-Output "No RecoveryPlanContext supplied. Manual test mode."
}

# TODO: Managed Identity 로그인
# Connect-AzAccount -Identity

# TODO: RecoveryPlanContext.VmMap에서 복구 VM 목록 추출
# foreach ($vmInfo in $RecoveryPlanContext.VmMap.PSObject.Properties) {
#   $vmName = $vmInfo.Name
#   Write-Output "Processing recovered VM: $vmName"
# }

# TODO: NSG 연결 확인
# TODO: Internal Load Balancer Backend Pool 등록
# TODO: Private DNS Record 변경
# TODO: VM Extension 재설치
# TODO: RBAC Role Assignment 재적용
# TODO: AWX / Ansible Automation Platform Webhook 호출

Write-Output "[DR] Post-failover runbook completed."
