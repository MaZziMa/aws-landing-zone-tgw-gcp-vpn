param(
  [string]$Terraform = "terraform",
  [switch]$PlanOnly,
  [switch]$SkipInit
)

$ErrorActionPreference = "Stop"

$Root = Resolve-Path (Join-Path $PSScriptRoot "..")
$Stacks = @(
  "envs/us-east-1/network",
  "envs/us-east-1/workloads/dev",
  "envs/us-east-1/workloads/prod",
  "envs/us-east-1/aws-gcp-vpn"
)

function Invoke-Terraform {
  param(
    [Parameter(Mandatory = $true)]
    [string]$StackPath,
    [Parameter(Mandatory = $true)]
    [string[]]$Arguments
  )

  & $Terraform "-chdir=$StackPath" @Arguments
  if ($LASTEXITCODE -ne 0) {
    throw "Terraform failed in $StackPath with exit code $LASTEXITCODE."
  }
}

foreach ($Stack in $Stacks) {
  $StackPath = Join-Path $Root $Stack
  Write-Host "Processing $Stack"

  if (-not $SkipInit) {
    Invoke-Terraform -StackPath $StackPath -Arguments @("init")
  }

  Invoke-Terraform -StackPath $StackPath -Arguments @("plan", "-input=false", "-out=tfplan")

  if (-not $PlanOnly) {
    Invoke-Terraform -StackPath $StackPath -Arguments @("apply", "-input=false", "tfplan")
  }
}
