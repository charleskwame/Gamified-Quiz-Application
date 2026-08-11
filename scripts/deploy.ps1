<#
.SYNOPSIS
  Trigger a GitHub Actions release deployment via repository_dispatch.

.DESCRIPTION
  Sends a custom "deploy" event to the GitHub API, which starts the
  .github/workflows/deploy.yml workflow on the chosen branch.

.EXAMPLE
  .\scripts\deploy.ps1
  .\scripts\deploy.ps1 -Version 1.2.0
  .\scripts\deploy.ps1 -Version 1.2.0 -Branch main

.NOTES
  Requires the GH_DEPLOY_TOKEN environment variable (a fine-grained PAT
  with "Contents: Read and write" on the repo). Set it once with:
    $env:GH_DEPLOY_TOKEN = "<your-token>"
#>
param(
    [string]$Version,
    [string]$Repo = "charleskwame/Gamified-Quiz-Application",
    [string]$Branch = "main"
)

$ErrorActionPreference = "Stop"

$token = $env:GH_DEPLOY_TOKEN
if ([string]::IsNullOrEmpty($token)) {
    Write-Host "Missing token. Set it first with:" -ForegroundColor Red
    Write-Host "  `$env:GH_DEPLOY_TOKEN = `"<your-token>`"" -ForegroundColor Yellow
    exit 1
}

# If no version given, read it from pubspec.yaml (e.g. "1.1.0+3" -> "1.1.0")
if ([string]::IsNullOrEmpty($Version)) {
    $line = Select-String -Path "$PSScriptRoot\..\pubspec.yaml" -Pattern '^version:\s*' | Select-Object -First 1
    if ($line) {
        $Version = (($line.Line -split '\s+')[1] -replace '\+.*$', '')
    }
}

$payload = @{
    event_type     = "deploy"
    client_payload = @{
        version = $Version
        branch  = $Branch
    }
} | ConvertTo-Json -Depth 5

$headers = @{
    Authorization         = "Bearer $token"
    Accept                = "application/vnd.github+json"
    "X-GitHub-Api-Version" = "2022-11-28"
}

$uri = "https://api.github.com/repos/$Repo/dispatches"

try {
    Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $payload -ContentType "application/json" | Out-Null
}
catch {
    Write-Host "Dispatch failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Deployment triggered for $Repo (branch: $Branch)" -ForegroundColor Green
if ($Version) { Write-Host "   Version: $Version" }
Write-Host "   Watch it at: https://github.com/$Repo/actions" -ForegroundColor Cyan
