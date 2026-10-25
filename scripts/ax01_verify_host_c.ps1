param(
    [string]$MatlabRoot = 'D:/Program Files/MATLAB/R2026b',
    [string]$Compiler = 'C:/ProgramData/MATLAB/SupportPackages/R2026b/3P.instrset/mingw_w64.instrset/bin/gcc.exe'
)
$ErrorActionPreference = 'Stop'
$axRoot = Split-Path -Parent $PSScriptRoot
$axMatlab = Join-Path $MatlabRoot 'bin/matlab.exe'
$axScripts = $PSScriptRoot.Replace('\','/').Replace("'","''")
Push-Location -LiteralPath $axRoot
try {
    & $axMatlab -batch "addpath('$axScripts'); ax01_build_r5; ax01_verify_r5(false);"
    if ($LASTEXITCODE -ne 0) { throw 'MATLAB model comparison or C generation failed.' }
    $axGenerated = Join-Path $axRoot '.runtime/ax01/codegen/AXU5EV_R5_Control_ert_rtw'
    $axRunner = Join-Path $axRoot '.runtime/ax01/r5_c_replay.exe'
    & $Compiler -std=c11 -O0 -fno-fast-math "-I$axGenerated" `
        (Join-Path $axRoot 'verification/r5/r5_c_replay.c') `
        "$axGenerated/AXU5EV_R5_Control.c" "$axGenerated/rtGetNaN.c" `
        "$axGenerated/rt_nonfinite.c" -lm -o $axRunner
    if ($LASTEXITCODE -ne 0) { throw 'Generated C compilation failed.' }
    $axEvidence = @()
    foreach ($axCase in @('position_reset','speed_slew','current_test','alignment_full','alignment_reset_fault')) {
        $axResult = & $axRunner (Join-Path $axRoot ".runtime/ax01/$axCase.csv")
        if ($LASTEXITCODE -ne 0) { throw "Generated C replay failed: $axCase" }
        $axEvidence += "$axCase $axResult"
        Write-Output $axEvidence[-1]
    }
    $axEvidence | Set-Content -LiteralPath (Join-Path $axRoot '.runtime/ax01/host_c_result.log') -Encoding utf8
} finally {
    Pop-Location
}
