param([switch]$Rendered)
$ErrorActionPreference = 'Stop'
$prototypeRoot = Split-Path $PSScriptRoot -Parent
$godotExe = Join-Path $PSScriptRoot 'Godot_v4.7.2-stable_win64_console.exe'
$evidencePath = Join-Path $prototypeRoot 'artifacts'
$env:APPDATA = Join-Path $prototypeRoot '.runtime'
$env:LOCALAPPDATA = $env:APPDATA
$env:SPACE_BETRAYAL_EVIDENCE = $evidencePath
New-Item -ItemType Directory -Path $evidencePath,$env:APPDATA -Force | Out-Null
$cases = @(
    @{Name='hunter-test'; Args=@('--script','res://tests/hunter_test.gd')},
    @{Name='touch-ui'; Args=@('--script','res://tests/touch_ui_test.gd')},
    @{Name='rules'; Args=@('--script','res://tests/rules_test.gd')},
    @{Name='integration'; Args=@('--fixed-fps','60','--','--integration')},
    @{Name='bots-12'; Args=@('--fixed-fps','60','--','--bot-simulation')},
    @{Name='bots-40'; Args=@('--fixed-fps','60','--','--bot-simulation-40')}
)
foreach ($case in $cases) {
    $logPath = Join-Path $evidencePath ($case.Name + '.log')
    & $godotExe --headless --path $prototypeRoot --log-file $logPath @($case.Args)
    if ($LASTEXITCODE -ne 0) { throw ($case.Name + ' failed: ' + $LASTEXITCODE) }
    if (Select-String -LiteralPath $logPath -Pattern 'SCRIPT ERROR:' -Quiet) { throw ($case.Name + ' reported a script error') }
}
$nativeExe = Join-Path $prototypeRoot 'builds\Windows\SpaceBetrayal.exe'
$nativeLog = Join-Path $evidencePath 'packaged-integration.log'
$nativeProcess = Start-Process -FilePath $nativeExe -ArgumentList @('--headless','--fixed-fps','60','--log-file',('"' + $nativeLog + '"'),'--','--integration') -WindowStyle Hidden -Wait -PassThru
if ($nativeProcess.ExitCode -ne 0) { throw ('Packaged integration failed: ' + $nativeProcess.ExitCode) }
if (-not (Select-String -LiteralPath $nativeLog -Pattern 'INTEGRATION PASS' -Quiet)) { throw 'Packaged integration pass marker absent' }
if (Select-String -LiteralPath $nativeLog -Pattern 'SCRIPT ERROR:' -Quiet) { throw 'Packaged integration reported a script error' }
if ($Rendered) {
    $hunterInputLog = Join-Path $evidencePath 'hunter-rendered-input.log'
    $hunterInput = Start-Process -FilePath $godotExe -ArgumentList @('--path',('"' + $prototypeRoot + '"'),'--audio-driver','Dummy','--log-file',('"' + $hunterInputLog + '"'),'--script','res://tests/hunter_test.gd') -WindowStyle Hidden -Wait -PassThru
    if ($hunterInput.ExitCode -ne 0 -or (Select-String -LiteralPath $hunterInputLog -Pattern 'SCRIPT ERROR:|HUNTER FAIL:' -Quiet)) { throw 'Rendered Hunter input test failed' }
    foreach ($mode in 'menu','game','touch','meeting','hunter','hunter-touch') {
        $renderLog = Join-Path $evidencePath ('render-' + $mode + '.log')
        $renderProcess = Start-Process -FilePath $nativeExe -ArgumentList @('--audio-driver','Dummy','--log-file',('"' + $renderLog + '"'),'--',('--capture-' + $mode)) -WindowStyle Hidden -Wait -PassThru
        if ($renderProcess.ExitCode -ne 0) { throw ('Rendered ' + $mode + ' failed: ' + $renderProcess.ExitCode) }
        if (-not (Select-String -LiteralPath $renderLog -Pattern ('CAPTURE ' + $mode + ' 0') -Quiet)) { throw ('Capture absent: ' + $mode) }
        if (Select-String -LiteralPath $renderLog -Pattern 'SCRIPT ERROR:' -Quiet) { throw ('Render script error: ' + $mode) }
    }
}
$javaExe = Join-Path $PSScriptRoot 'jdk\jdk-17.0.20.1+1\bin\java.exe'
$apksigner = Join-Path $PSScriptRoot 'android\build-tools\35.0.1\lib\apksigner.jar'
$apkPath = Join-Path $prototypeRoot 'builds\Android\SpaceBetrayal-0.2.0.apk'
& $javaExe -jar $apksigner verify --verbose --print-certs $apkPath | Set-Content -LiteralPath (Join-Path $evidencePath 'apk-signature.log')
if ($LASTEXITCODE -ne 0) { throw 'APK signature verification failed' }
Write-Output 'PASS: rules, integration, simulations, packaged native integration, APK signature'
