$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$scriptPath = Join-Path $PSScriptRoot 'firebase_emulator_rules_smoke.mjs'
$nodeExe = $null

if ($env:NVM_HOME) {
  $installRoot = Join-Path $env:NVM_HOME 'installs'
  if (Test-Path -LiteralPath $installRoot) {
    $nodeExe = Get-ChildItem -LiteralPath $installRoot -Directory |
      ForEach-Object {
        $candidate = Join-Path $_.FullName 'node.exe'
        if (Test-Path -LiteralPath $candidate) { $candidate }
      } |
      Select-Object -First 1
  }
}

if (-not $nodeExe) {
  $nodeCommand = Get-Command node.exe -ErrorAction SilentlyContinue
  if ($nodeCommand) { $nodeExe = $nodeCommand.Source }
}
if (-not $nodeExe) { throw 'Node.js was not found for the emulator test.' }

Push-Location $repoRoot
try {
  & $nodeExe $scriptPath
  exit $LASTEXITCODE
} finally {
  Pop-Location
}
