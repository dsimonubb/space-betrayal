param([string]$GodotExe='godot',[ValidateSet('Windows','Android')][string]$Target='Windows')
$ErrorActionPreference='Stop'
$nativeRoot=Join-Path (Split-Path $PSScriptRoot -Parent) 'native'
New-Item -ItemType Directory -Force -Path (Join-Path $nativeRoot 'builds/Windows'),(Join-Path $nativeRoot 'builds/Android') | Out-Null
$mode=if($Target -eq 'Android'){'--export-debug'}else{'--export-release'}
& $GodotExe --headless --path $nativeRoot $mode $Target
if($LASTEXITCODE -ne 0){throw ('Export failed: '+$Target)}
