@echo off
setlocal
set "qa_root=%TEMP%\PokemonTactics-check-%RANDOM%-%RANDOM%"
mkdir "%qa_root%"
set "APPDATA=%qa_root%\Roaming"
set "LOCALAPPDATA=%qa_root%\Local"
mkdir "%APPDATA%"
mkdir "%LOCALAPPDATA%"
start "" /wait "%~dp0PokemonTactics.exe" -- --smoke-report="%qa_root%\arranque.json"
set "qa_exit=%errorlevel%"
echo Informe de arranque: %qa_root%\arranque.json
echo La prueba usa un perfil aislado y no cambia tu partida habitual.
if /I not "%~1"=="--sin-pausa" pause
exit /b %qa_exit%
