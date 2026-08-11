<#
.SYNOPSIS
  Trigger a GitHub Actions release deployment via repository_dispatch.

.DESCRIPTION
  Sends a custom "deploy" event to the GitHub API, which starts the
  .github/workflows/deploy.yml workflow on the chosen branch.

.EXAMPLE
  .\scripts\deploy.ps1                  # auto-increment patch from latest release
  .\scripts\deploy.ps1 -Version 1.2.0   # explicit version
  .\scripts\deploy.ps1 -NoAutoIncrement # use the static version from pubspec.yaml

.NOTES
  Requires the GH_DEPLOY_TOKEN environment variable (a fine-grained PAT
  with "Contents: Read and write" on the repo). Set it once with:
    $env:GH_DEPLOY_TOKEN = "<your-token>"
#>
param(
    [string]$Version,
    [switch]$NoAutoIncrement,
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

# --- Version resolution ------------------------------------------------------
# 1) -Version        -> explicit override
# 2) default         -> auto-increment the patch from the latest GitHub release
# 3) -NoAutoIncrement -> fall back to the version in pubspec.yaml
function Get-LatestReleaseVersion {
    param([string]$Repo, [hashtable]$Headers)
    try {
        $rel = Invoke-RestMethod -Uri "https://api.github.com/repos/$Repo/releases/latest" -Headers $Headers
        return $rel.tag_name
    }
    catch {
        return $null # no releases yet
    }
}

function ConvertTo-NextPatchVersion {
    param([string]$Tag)
    $parts = (($Tag -replace '^v', '') -split '\.')
    if ($parts.Count -lt 3) { return ($Tag -replace '^v', '') }
    $patch = [int]$parts[2] + 1
    return "$($parts[0]).$($parts[1]).$patch"
}

function ConvertTo-BuildNumber {
    param([string]$Version)
    $parts = (($Version -replace '^v', '') -split '\.')
    $major = if ($parts.Count -gt 0) { [int]$parts[0] } else { 0 }
    $minor = if ($parts.Count -gt 1) { [int]$parts[1] } else { 0 }
    $patch = if ($parts.Count -gt 2) { [int]$parts[2] } else { 0 }
    return ($major * 10000) + ($minor * 100) + $patch
}

$headers = @{
    Authorization         = "Bearer $token"
    Accept                = "application/vnd.github+json"
    "X-GitHub-Api-Version" = "2022-11-28"
}

if ([string]::IsNullOrEmpty($Version)) {
    if (-not $NoAutoIncrement) {
        $latest = Get-LatestReleaseVersion -Repo $Repo -Headers $headers
        if ($latest) {
            $Version = ConvertTo-NextPatchVersion -Tag $latest
            Write-Host "Auto-incrementing: $latest -> v$Version" -ForegroundColor Cyan
        }
    }
}
if ([string]::IsNullOrEmpty($Version)) {
    # Fall back to pubspec.yaml (e.g. "1.1.0+3" -> "1.1.0")
    $line = Select-String -Path "$PSScriptRoot\..\pubspec.yaml" -Pattern '^version:\s*' | Select-Object -First 1
    if ($line) {
        $Version = (($line.Line -split '\s+')[1] -replace '\+.*$', '')
    }
}
if ([string]::IsNullOrEmpty($Version)) {
    Write-Host "Could not determine a version. Pass -Version explicitly." -ForegroundColor Red
    exit 1
}

$buildNumber = ConvertTo-BuildNumber -Version $Version

$payload = @{
    event_type     = "deploy"
    client_payload = @{
        version     = $Version
        buildNumber = $buildNumber
        branch      = $Branch
    }
} | ConvertTo-Json -Depth 5

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
if ($buildNumber) { Write-Host "   Build number: $buildNumber" }
Write-Host "   Watch it at: https://github.com/$Repo/actions" -ForegroundColor Cyan
