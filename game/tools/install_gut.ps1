#Requires -Version 5.1
<#
.SYNOPSIS
    Downloads, checksum-verifies, and installs the pinned GUT test addon.

.DESCRIPTION
    Downloads the pinned GUT release archive, verifies its SHA-256 checksum
    against the value pinned below, and extracts only the addons/gut folder
    into game/addons/gut/ (gitignored). Fails closed on any checksum
    mismatch or missing plugin.cfg: no partial install, non-zero exit,
    existing addon left untouched.

.PARAMETER Force
    Reinstall even if the pinned version is already installed.
#>
param(
    [switch]$Force
)

$ErrorActionPreference = "Stop"

# Pinned release. Update both constants together when bumping GUT.
$GUT_VERSION = "9.7.1"
$GUT_SHA256 = "14969aa46adc84aa08cdd21b9f6d1a64addd92ae60b36f02d0521ed305aa4086"
$GUT_URL = "https://github.com/bitwes/Gut/archive/refs/tags/v$GUT_VERSION.zip"

# Resolve paths from this script's own location, never the caller's cwd.
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$GameDir = Split-Path -Parent $ScriptDir
$AddonsDir = Join-Path $GameDir "addons"
$GutDir = Join-Path $AddonsDir "gut"
$TmpDir = Join-Path $AddonsDir ".gut-tmp"
$VersionFile = Join-Path $GutDir ".gut-version"

function Write-Info($msg) { Write-Host "[install_gut] $msg" }
function Write-Err($msg) { Write-Host "[install_gut] ERROR: $msg" -ForegroundColor Red }

# Idempotency: skip if the pinned version is already installed, unless -Force.
if (-not $Force -and (Test-Path $VersionFile)) {
    $installed = Get-Content $VersionFile -Raw
    if ($installed.Trim() -eq $GUT_VERSION) {
        Write-Info "GUT $GUT_VERSION already installed (use -Force to reinstall)."
        exit 0
    }
}

if (Test-Path $TmpDir) {
    Remove-Item -Recurse -Force $TmpDir
}
New-Item -ItemType Directory -Force -Path $TmpDir | Out-Null

$ZipPath = Join-Path $TmpDir "gut-$GUT_VERSION.zip"

try {
    Write-Info "Downloading GUT $GUT_VERSION from $GUT_URL ..."
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $GUT_URL -OutFile $ZipPath -UseBasicParsing

    Write-Info "Verifying SHA-256 checksum ..."
    $actualHash = (Get-FileHash -Path $ZipPath -Algorithm SHA256).Hash
    if ($actualHash.ToLowerInvariant() -ne $GUT_SHA256.ToLowerInvariant()) {
        Write-Err "Checksum mismatch."
        Write-Err "  Expected: $GUT_SHA256"
        Write-Err "  Actual:   $($actualHash.ToLowerInvariant())"
        Remove-Item -Recurse -Force $TmpDir -ErrorAction SilentlyContinue
        exit 1
    }
    Write-Info "Checksum verified."

    Write-Info "Extracting archive ..."
    $ExtractDir = Join-Path $TmpDir "extracted"
    Expand-Archive -Path $ZipPath -DestinationPath $ExtractDir -Force

    $SourceGutDir = Join-Path $ExtractDir "Gut-$GUT_VERSION\addons\gut"
    $PluginCfg = Join-Path $SourceGutDir "plugin.cfg"
    if (-not (Test-Path $PluginCfg)) {
        Write-Err "plugin.cfg not found at expected path after extraction: $PluginCfg"
        Remove-Item -Recurse -Force $TmpDir -ErrorAction SilentlyContinue
        exit 1
    }

    Write-Info "Installing to $GutDir ..."
    if (Test-Path $GutDir) {
        Remove-Item -Recurse -Force $GutDir
    }
    New-Item -ItemType Directory -Force -Path $AddonsDir | Out-Null
    Move-Item -Path $SourceGutDir -Destination $GutDir

    Set-Content -Path $VersionFile -Value $GUT_VERSION -NoNewline

    Write-Info "GUT $GUT_VERSION installed successfully."
    exit 0
}
finally {
    if (Test-Path $TmpDir) {
        Remove-Item -Recurse -Force $TmpDir -ErrorAction SilentlyContinue
    }
}
