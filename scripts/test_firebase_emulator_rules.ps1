$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$firebaseCli = Join-Path $env:APPDATA 'npm\node_modules\firebase-tools\lib\bin\firebase.js'
$nodeExe = $null

# Invoke the installed Node binary directly so an unselected NVM shim cannot block tests.
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
if (-not $nodeExe) { throw 'Node.js was not found for the Firebase emulator test.' }
if (-not (Test-Path -LiteralPath $firebaseCli)) {
  throw "Firebase CLI entry point was not found at $firebaseCli."
}

# Isolate each run so test cleanup cannot touch app data in another emulator project.
$projectId = 'demo-upbridge-rules-' + [guid]::NewGuid().ToString('N')
$previousProjectId = $env:UPBRIDGE_FIREBASE_EMULATOR_PROJECT_ID
$previousConfigHome = $env:XDG_CONFIG_HOME
$env:UPBRIDGE_FIREBASE_EMULATOR_PROJECT_ID = $projectId
$configDir = Join-Path $env:TEMP 'upbridge-firebase-cli-config'
New-Item -ItemType Directory -Path $configDir -Force | Out-Null
$env:XDG_CONFIG_HOME = $configDir
$testCommand = 'powershell -NoProfile -ExecutionPolicy Bypass -File scripts/run_firebase_emulator_rules_smoke.ps1'

Push-Location $repoRoot
try {
  & $nodeExe $firebaseCli emulators:exec --project $projectId --only auth,firestore $testCommand
  $exitCode = $LASTEXITCODE
} finally {
  if ($null -eq $previousProjectId) {
    Remove-Item Env:UPBRIDGE_FIREBASE_EMULATOR_PROJECT_ID -ErrorAction SilentlyContinue
  } else {
    $env:UPBRIDGE_FIREBASE_EMULATOR_PROJECT_ID = $previousProjectId
  }
  if ($null -eq $previousConfigHome) {
    Remove-Item Env:XDG_CONFIG_HOME -ErrorAction SilentlyContinue
  } else {
    $env:XDG_CONFIG_HOME = $previousConfigHome
  }
  Pop-Location
}

exit $exitCode
