# Runs scripts/mentorship_rules_emulator_test.mjs against throwaway Auth and
# Firestore emulators. Needs Node.js, Java 11+ and firebase-tools
# (npm install -g firebase-tools). Never touches a real Firebase project.
$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot

$node = Get-Command node.exe -ErrorAction SilentlyContinue
if (-not $node) { throw 'Node.js was not found. Install Node.js 18 or newer.' }
if (-not (Get-Command java.exe -ErrorAction SilentlyContinue)) {
  throw 'Java was not found. The Firestore emulator needs Java 11 or newer.'
}

$firebaseJs = Join-Path $env:APPDATA 'npm\node_modules\firebase-tools\lib\bin\firebase.js'
if (Test-Path -LiteralPath $firebaseJs) {
  $firebase = @($node.Source, $firebaseJs)
} elseif (Get-Command firebase -ErrorAction SilentlyContinue) {
  $firebase = @('firebase')
} else {
  throw 'firebase-tools was not found. Run: npm install -g firebase-tools'
}

# A unique demo-* project keeps each run isolated from real and other test data.
$projectId = 'demo-upbridge-mentorship-' + [guid]::NewGuid().ToString('N').Substring(0, 12)
$previousProjectId = $env:UPBRIDGE_FIREBASE_EMULATOR_PROJECT_ID
$env:UPBRIDGE_FIREBASE_EMULATOR_PROJECT_ID = $projectId
$testCommand = 'node scripts/mentorship_rules_emulator_test.mjs'

Push-Location $repoRoot
try {
  $exe = $firebase[0]
  $firebaseArgs = @($firebase | Select-Object -Skip 1) + @('emulators:exec', '--project', $projectId, '--only', 'auth,firestore', $testCommand)
  & $exe @firebaseArgs
  $exitCode = $LASTEXITCODE
} finally {
  if ($null -eq $previousProjectId) {
    Remove-Item Env:UPBRIDGE_FIREBASE_EMULATOR_PROJECT_ID -ErrorAction SilentlyContinue
  } else {
    $env:UPBRIDGE_FIREBASE_EMULATOR_PROJECT_ID = $previousProjectId
  }
  Pop-Location
}

exit $exitCode
