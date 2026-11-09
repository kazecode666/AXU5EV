param([ValidateSet('base','integrate','synth','audit','validate','build','all','reports','sdf')][string]$Stage='all',
      [Parameter(Mandatory=$true)][string]$Output)
$ErrorActionPreference='Stop'
$root=Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $root
if($Stage -in @('base','validate','all') -and (Test-Path -LiteralPath $Output)){throw 'Choose a new output directory'}
$hadMcPwm=Test-Path Env:MC_PWM
$originalMcPwm=$env:MC_PWM
$hadTest=Test-Path Env:AX03B3_TEST
$originalTest=$env:AX03B3_TEST
try {
 $env:MC_PWM='1'
 $env:AX03B3_TEST='0'
 if($Stage -ne 'sdf'){& "$PSScriptRoot/ax03b3_build_hw.ps1" -Stage $Stage -Output $Output}
 if($Stage -in @('all','build','sdf')) {
  if(Test-Path -LiteralPath (Join-Path $Output 'timing_pl')){throw 'Timing export exists; preserve completed output'}
  & 'E:/AMDDesignTools/2026.1/Vivado/bin/vivado.bat' -mode batch `
   -source hardware/axu5ev/motor_control/export_timing.tcl `
   -log "$Output.pl_sdf.log" -journal "$Output.pl_sdf.jou" -tclargs $Output
  if($LASTEXITCODE -ne 0){throw 'Routed SDF export failed'}
 }
} finally {
 if($hadMcPwm){$env:MC_PWM=$originalMcPwm}
 else {$env:MC_PWM=$null}
 if($hadTest){$env:AX03B3_TEST=$originalTest}
 else {$env:AX03B3_TEST=$null}
}
