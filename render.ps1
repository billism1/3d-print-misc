# render.ps1
# Render a single .scad file to an STL in the publication/ folder.
# An existing STL of the same name is overwritten.
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File render.ps1 <scad-file>
#
# The argument may be a full path, or just a name found in src/
# (with or without the .scad extension). Examples:
#   render.ps1 trophy_cup
#   render.ps1 src\trophy_cup.scad
#   render.ps1 C:\path\to\model.scad

param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$ScadFile
)

$ErrorActionPreference = 'Stop'

$root   = Split-Path -Parent $MyInvocation.MyCommand.Definition
$srcDir = Join-Path $root 'src'
$outDir = Join-Path $root 'publication'

# Resolve the .scad file: try the arg as-is, then src/<arg>, then src/<arg>.scad.
$candidatePaths = @(
    $ScadFile,
    (Join-Path $srcDir $ScadFile),
    (Join-Path $srcDir ($ScadFile + '.scad'))
)
$scad = $candidatePaths | Where-Object { Test-Path $_ -PathType Leaf } | Select-Object -First 1
if (-not $scad) {
    Write-Error "Cannot find .scad file for '$ScadFile' (looked in src/ too)."
}
$scad = (Resolve-Path $scad).Path

# Locate the OpenSCAD executable.
$candidates = @(
    'C:\Program Files\OpenSCAD\openscad.exe',
    'C:\Program Files\OpenSCAD (Nightly)\openscad.exe'
)
$openscad = $candidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $openscad) {
    $openscad = (Get-Command openscad -ErrorAction SilentlyContinue).Source
}
if (-not $openscad) {
    Write-Error 'OpenSCAD executable not found. Install it or add it to PATH.'
}

# Ensure the output folder exists.
if (-not (Test-Path $outDir)) {
    New-Item -ItemType Directory -Path $outDir | Out-Null
}

$baseName = [System.IO.Path]::GetFileNameWithoutExtension($scad)
$stl      = Join-Path $outDir ($baseName + '.stl')
Write-Host "Rendering $baseName.scad -> publication\$baseName.stl"

$errFile = [System.IO.Path]::GetTempFileName()
$proc = Start-Process -FilePath $openscad `
    -ArgumentList @('-o', $stl, $scad) `
    -NoNewWindow -Wait -PassThru -RedirectStandardError $errFile

if ($proc.ExitCode -ne 0) {
    Write-Host "  FAILED (exit $($proc.ExitCode))" -ForegroundColor Red
    Get-Content $errFile | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
    Remove-Item $errFile -ErrorAction SilentlyContinue
    exit 1
}
Remove-Item $errFile -ErrorAction SilentlyContinue
Write-Host "  OK" -ForegroundColor Green
