param(
    [Parameter(Mandatory=$true)] [string] $AwxUrl,
    [Parameter(Mandatory=$true)] [string] $JobTemplateId,
    [Parameter(Mandatory=$true)] [string] $Token,
    [Parameter(Mandatory=$false)] [string] $ExtraVarsJson = "{}"
)

$headers = @{
    "Authorization" = "Bearer $Token"
    "Content-Type"  = "application/json"
}

$body = @{
    extra_vars = $ExtraVarsJson | ConvertFrom-Json
} | ConvertTo-Json -Depth 20

$uri = "$AwxUrl/api/v2/job_templates/$JobTemplateId/launch/"

Write-Output "Invoking AWX Job Template: $JobTemplateId"
$response = Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -Body $body
$response | ConvertTo-Json -Depth 20
