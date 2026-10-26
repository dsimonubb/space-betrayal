param([string]$GodotExe = 'godot')
$ErrorActionPreference='Stop'
$nativeRoot=Join-Path (Split-Path $PSScriptRoot -Parent) 'native'
$testRuntime=Join-Path $nativeRoot '.runtime'
New-Item -ItemType Directory -Force -Path $testRuntime,(Join-Path $nativeRoot 'artifacts') | Out-Null
$env:APPDATA=$testRuntime
$env:LOCALAPPDATA=$testRuntime
foreach($test in @('rules_test','hunter_test','touch_ui_test')){
    & $GodotExe --headless --path $nativeRoot --script ("res://tests/"+$test+".gd")
    if($LASTEXITCODE -ne 0){throw ($test+' failed')}
}
