param(
    [string] $Python,
    [ValidateSet('SELFTEST','REAL')][string] $Demo,
    [string] $HostCompiler,
    [ValidateSet('SELFTEST','REAL')][string] $Prepare,
    [string] $Output
)
$ErrorActionPreference = 'Stop'
if (($Prepare -and $Demo) -or ($Prepare -and -not $Output) -or ($Output -and -not $Prepare)) {
    throw 'Specify -Prepare SELFTEST|REAL with -Output, or use -Demo without -Prepare.'
}
if ($Output) {
    $Output = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Output)
}
$repo = Split-Path -Parent $PSScriptRoot
if (-not $Python) {
    $venv = Join-Path $repo '.runtime/studio/venv/Scripts/python.exe'
    $Python = if (Test-Path -LiteralPath $venv) { $venv } else { 'python' }
} elseif (Test-Path -LiteralPath $Python -PathType Leaf) {
    $Python = (Resolve-Path -LiteralPath $Python).Path
}
if ($HostCompiler -and (Test-Path -LiteralPath $HostCompiler -PathType Leaf)) {
    $HostCompiler = (Resolve-Path -LiteralPath $HostCompiler).Path
}
Push-Location $repo
try {
    if ($Demo) {
        $options = @('tests/run_motor_control_studio_demo.py', '--profile', $Demo)
        if ($HostCompiler) { $options += @('--cc', $HostCompiler) }
    } else {
        $options = @('-m', 'scripts.motor_control_studio')
        if ($Prepare) { $options += @('--prepare', $Prepare, '--output', $Output) }
    }
    & $Python @options
    exit $LASTEXITCODE
} finally {
    Pop-Location
}
