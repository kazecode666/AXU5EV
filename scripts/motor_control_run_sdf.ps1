param([Parameter(Mandatory=$true)][string]$Hardware,
      [Parameter(Mandatory=$true)][string]$RunDir,
      [ValidateSet('slow','fast')][string]$Corner='slow',
      [ValidateRange(1,2147483647)][int]$ToolTimeoutMs=10800000,
      [string]$Python='python',
      [string]$CancelFile='',
      [switch]$XelabO0,
      [switch]$XelabDiagnostics,
      [string]$VivadoBin='E:/AMDDesignTools/2026.1/Vivado/bin')
$ErrorActionPreference='Stop'
& "$PSScriptRoot/pwm_adc_run_sdf.ps1" -Hardware $Hardware -RunDir $RunDir `
 -Corner $Corner -VivadoBin $VivadoBin -Python $Python -CancelFile $CancelFile -XelabO0:$XelabO0 -XelabDiagnostics:$XelabDiagnostics -ToolTimeoutMs $ToolTimeoutMs -Testbench 'verification/motor_control/timing_tb.sv' `
 -Scope 'routed full functional PL; PWM ILA black box; structural dbg_hub retained; PS clock/reset and AXI transaction sources substituted'
