param([Parameter(Mandatory=$true)][string]$Hardware,
      [Parameter(Mandatory=$true)][string]$RunDir,
      [ValidateSet('slow','fast')][string]$Corner='slow',
      [string]$VivadoBin='E:/AMDDesignTools/2026.1/Vivado/bin')
$ErrorActionPreference='Stop'
& "$PSScriptRoot/pwm_adc_run_sdf.ps1" -Hardware $Hardware -RunDir $RunDir `
 -Corner $Corner -VivadoBin $VivadoBin -Testbench 'verification/encoder_feedback/timing_tb.sv'
