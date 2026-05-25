param(
  [string]$Terraform = "terraform",
  [switch]$Init
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

Push-Location $Root
try {
  & $Terraform fmt -check -recursive
  if ($LASTEXITCODE -ne 0) {
    throw "Terraform fmt check failed with exit code $LASTEXITCODE."
  }

  foreach ($Stack in $Stacks) {
    $StackPath = Join-Path $Root $Stack
    Write-Host "Validating $Stack"

    if ($Init) {
      Invoke-Terraform -StackPath $StackPath -Arguments @("init", "-backend=false")
    }

    Invoke-Terraform -StackPath $StackPath -Arguments @("validate")
  }
}
finally {
  Pop-Location
}
