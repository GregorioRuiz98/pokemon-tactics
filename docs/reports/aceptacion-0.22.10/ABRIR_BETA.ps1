param([switch]$Fixture, [string]$Session = '', [string]$GodotPath = '', [string]$ProjectPath = '')
$ErrorActionPreference = 'Stop'
$betaExecutable = Join-Path $PSScriptRoot '../PokemonTactics.exe'
if (-not (Test-Path -LiteralPath $betaExecutable)) { throw 'Copia este kit junto al ejecutable, dentro de PRUEBAS_HUMANAS.' }
if ($Fixture -and ([string]::IsNullOrWhiteSpace($GodotPath) -or [string]::IsNullOrWhiteSpace($ProjectPath) -or -not (Test-Path -LiteralPath $GodotPath -PathType Leaf) -or -not (Test-Path -LiteralPath (Join-Path $ProjectPath 'project.godot') -PathType Leaf))) { throw 'El fixture avanzado requiere -GodotPath (Godot4.7.2) y -ProjectPath (carpeta godot del proyecto fuente). El juego normal abre sin esos parámetros.' }
$previousAppData = $env:APPDATA
$previousLocalData = $env:LOCALAPPDATA
if ($Session -and $Session -notmatch '^session-[a-f0-9]{32}$') { throw 'Elige el nombre session-* de un perfil del kit.' }
if (-not $Session) { $Session = 'session-' + [Guid]::NewGuid().ToString('N') }
$betaProfileDir = Join-Path $PSScriptRoot ('perfiles/' + $Session)
Write-Host ('Perfil QA: ' + $Session)
New-Item -ItemType Directory -Path $betaProfileDir -Force | Out-Null
try {
    $env:APPDATA = $betaProfileDir
    $env:LOCALAPPDATA = $betaProfileDir
    if ($Fixture) { & $GodotPath --path $ProjectPath --script res://ui/manual_beta.gd }
    else { & $betaExecutable }
} finally {
    $env:APPDATA = $previousAppData
    $env:LOCALAPPDATA = $previousLocalData
}
