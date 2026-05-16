# render_all.ps1
# Render every src/*.scad file to an STL in the publication/ folder.
# Existing STLs of the same name are overwritten.
#
# Usage:  powershell -ExecutionPolicy Bypass -File render_all.ps1

$ErrorActionPreference = 'Stop'

$root    = Split-Path -Parent $MyInvocation.MyCommand.Definition
$srcDir  = Join-Path $root 'src'
$outDir  = Join-Path $root 'publication'

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

$scadFiles = Get-ChildItem -Path $srcDir -Filter '*.scad' | Sort-Object Name
if ($scadFiles.Count -eq 0) {
    Write-Warning "No .scad files found in $srcDir"
    return
}

# Build the render jobs. Default: one STL per .scad, named after the file.
# Some files render multiple variants by overriding parameters with -D.
$jobs = @()
foreach ($scad in $scadFiles) {
    if ($scad.Name -eq 'beer_can_koozy_negative.scad') {
        # Negative-only (as the file stands) and the basic koozy body variant.
        $jobs += @{ Src = $scad; Out = 'beer_can_koozy_negative.stl';
                    Defs = @('-D', 'show_koozy=false') }
        $jobs += @{ Src = $scad; Out = 'beer_can_koozy_example_basic.stl';
                    Defs = @('-D', 'show_koozy=true') }
    } else {
        $jobs += @{ Src = $scad; Out = ($scad.BaseName + '.stl'); Defs = @() }
    }
}

$failed = 0
foreach ($job in $jobs) {
    $stl = Join-Path $outDir $job.Out
    Write-Host "Rendering $($job.Src.Name) -> publication\$($job.Out)"

    $errFile = [System.IO.Path]::GetTempFileName()
    $proc = Start-Process -FilePath $openscad `
        -ArgumentList ($job.Defs + @('-o', $stl, $job.Src.FullName)) `
        -NoNewWindow -Wait -PassThru -RedirectStandardError $errFile

    if ($proc.ExitCode -ne 0) {
        $failed++
        Write-Host "  FAILED (exit $($proc.ExitCode))" -ForegroundColor Red
        Get-Content $errFile | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
    } else {
        Write-Host "  OK" -ForegroundColor Green
    }
    Remove-Item $errFile -ErrorAction SilentlyContinue
}

Write-Host ''
if ($failed -gt 0) {
    Write-Host "$failed of $($jobs.Count) render(s) failed." -ForegroundColor Red
    exit 1
} else {
    Write-Host "All $($jobs.Count) render(s) written to publication\." -ForegroundColor Green
}
