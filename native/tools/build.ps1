$ErrorActionPreference = 'Stop'
$prototypeRoot = Split-Path $PSScriptRoot -Parent
$env:APPDATA = Join-Path $prototypeRoot '.runtime'
$env:LOCALAPPDATA = $env:APPDATA
$env:JAVA_HOME = Join-Path $PSScriptRoot 'jdk\jdk-17.0.20.1+1'
$godotExe = Join-Path $PSScriptRoot 'Godot_v4.7.2-stable_win64_console.exe'
$evidencePath = Join-Path $prototypeRoot 'artifacts'
New-Item -ItemType Directory -Path $evidencePath,(Join-Path $prototypeRoot 'builds\Windows'),(Join-Path $prototypeRoot 'builds\Android') -Force | Out-Null
foreach ($preset in 'Windows','Android') {
    $mode = if ($preset -eq 'Windows') { '--export-release' } else { '--export-debug' }
    & $godotExe --headless --path $prototypeRoot $mode $preset *> (Join-Path $evidencePath ('export-' + $preset.ToLower() + '.log'))
    if ($LASTEXITCODE -ne 0) { throw ($preset + ' export failed') }
}
