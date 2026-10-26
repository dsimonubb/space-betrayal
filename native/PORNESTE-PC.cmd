@echo off
setlocal
if not exist "%~dp0builds\Windows\SpaceBetrayal.exe" goto missing
if not exist "%~dp0.runtime" mkdir "%~dp0.runtime"
set "APPDATA=%~dp0.runtime"
set "LOCALAPPDATA=%~dp0.runtime"
start "" "%~dp0builds\Windows\SpaceBetrayal.exe" --log-file "%~dp0.runtime\play.log"
exit /b
:missing
echo Pachetul Windows lipseste. Extrage arhiva completa sau deschide project.godot in Godot.
pause
