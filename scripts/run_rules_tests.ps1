$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$firebaseCli = Join-Path $env:APPDATA 'npm\node_modules\firebase-tools\lib\bin\firebase.js'
$nodeExe = $null

if ($env:NVM_HOME) {
  $installRoot = Join-Path $env:NVM_HOME 'installs'
  if (Test-Path -LiteralPath $installRoot) {
    $nodeExe = Get-ChildItem -LiteralPath $installRoot -Directory |
      ForEach-Object {
        try {
          [pscustomobject]@{
            Version = [version]$_.Name.TrimStart('v')
            Path = Join-Path $_.FullName 'node.exe'
          }
        } catch {
          $null
        }
      } |
      Where-Object { $_ -and (Test-Path -LiteralPath $_.Path) } |
      Sort-Object Version -Descending |
      Select-Object -First 1 -ExpandProperty Path
  }
}

if (-not $nodeExe) {
  $nodeCommand = Get-Command node.exe -ErrorAction SilentlyContinue
  if ($nodeCommand) { $nodeExe = $nodeCommand.Source }
}
if (-not $nodeExe) { throw 'Node.js was not found for Firestore rules tests.' }
if (-not (Test-Path -LiteralPath $firebaseCli)) {
  throw "Firebase CLI entry point was not found at $firebaseCli."
}

$projectId = 'demo-upbridge-rules-' + [guid]::NewGuid().ToString('N')
$configDir = Join-Path $env:TEMP 'upbridge-firebase-cli-config'
New-Item -ItemType Directory -Path $configDir -Force | Out-Null

$env:UPBRIDGE_RULES_PROJECT_ID = $projectId
$env:XDG_CONFIG_HOME = $configDir

Push-Location $repoRoot
try {
  & $nodeExe $firebaseCli emulators:exec --project $projectId --only firestore "node --test rules_tests/firestore.rules.test.mjs"
  $exitCode = $LASTEXITCODE
} finally {
  Remove-Item Env:UPBRIDGE_RULES_PROJECT_ID -ErrorAction SilentlyContinue
  Remove-Item Env:XDG_CONFIG_HOME -ErrorAction SilentlyContinue
  Pop-Location
}

exit $exitCode
