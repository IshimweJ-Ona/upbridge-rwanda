$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$firebaseConfigPath = Join-Path $repoRoot 'firebase.json'
$firebaseConfig = Get-Content -LiteralPath $firebaseConfigPath -Raw | ConvertFrom-Json
$projectId = $firebaseConfig.flutter.platforms.android.default.projectId
if (-not $projectId) { throw "No Firebase project ID found in $firebaseConfigPath" }

$firebaseEntry = Join-Path $env:APPDATA 'npm\node_modules\firebase-tools\lib\bin\firebase.js'
$nodeExe = $null

# Prefer an installed NVM version directly. This also works when the Node shim
# has no globally selected version, without changing the machine's NVM setting.
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

Push-Location $repoRoot
try {
  if ((Test-Path -LiteralPath $firebaseEntry) -and $nodeExe) {
    & $nodeExe $firebaseEntry emulators:start --project $projectId --only auth,firestore
  } else {
    $firebaseCommand = Get-Command firebase -ErrorAction Stop
    & $firebaseCommand.Source emulators:start --project $projectId --only auth,firestore
  }
  $exitCode = $LASTEXITCODE
} finally {
  Pop-Location
}

exit $exitCode
