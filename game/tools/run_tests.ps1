#Requires -Version 5.1
<#
.SYNOPSIS
    Runs the GUT test suite headlessly via the pinned console Godot binary.

.DESCRIPTION
    Resolves GODOT_BIN (env var, else the pinned default path), imports
    project resources, then runs the GUT suite headlessly. Exits 2 with a
    named remediation message if the Godot binary or the GUT addon is
    missing. Propagates GUT's exit code so a failing test fails this
    command.

.PARAMETER ExtraArgs
    Extra arguments forwarded verbatim to the GUT CLI, e.g.
    -gdir=res://tests/unit/core or -gselect=TestRunRng. These override the
    corresponding .gutconfig.json values for a focused/scoped run.
#>
param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$ExtraArgs
)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$GameDir = Split-Path -Parent $ScriptDir

$DefaultGodotBin = "C:\Users\jose2\Tools\Godot\Godot_v4.7.2-stable_win64_console.exe"
$GodotBin = if ($env:GODOT_BIN) { $env:GODOT_BIN } else { $DefaultGodotBin }

function Write-Info($msg) { Write-Host "[run_tests] $msg" }
function Write-Err($msg) { Write-Host "[run_tests] ERROR: $msg" -ForegroundColor Red }

if (-not (Test-Path $GodotBin)) {
    Write-Err "Godot binary not found at '$GodotBin'. Set the GODOT_BIN environment variable to the Godot 4.7.2 console executable."
    exit 2
}

$PluginCfg = Join-Path $GameDir "addons\gut\plugin.cfg"
if (-not (Test-Path $PluginCfg)) {
    Write-Err "GUT addon not found at 'addons\gut\plugin.cfg'. Run tools\install_gut.ps1 first."
    exit 2
}

Write-Info "Importing project resources ..."
$importArgs = @("--headless", "--path", $GameDir, "--import")
& $GodotBin @importArgs
if ($LASTEXITCODE -ne 0) {
    Write-Err "Import step failed with exit code $LASTEXITCODE."
    exit $LASTEXITCODE
}

Write-Info "Running GUT suite headlessly ..."
$testArgs = @(
    "--headless",
    "--path", $GameDir,
    "-s", "res://addons/gut/gut_cmdln.gd",
    "-gconfig=res://.gutconfig.json",
    "-gexit"
) + $ExtraArgs

& $GodotBin @testArgs
exit $LASTEXITCODE
