[CmdletBinding()]
param([Parameter(Mandatory=$true)][string]$Hardware,
      [Parameter(Mandatory=$true)][string]$RunDir,
      [ValidateSet('slow','fast')][string]$Corner='slow',
      [ValidateRange(1,2147483647)][int]$ToolTimeoutMs=1800000,
      [string]$VivadoBin='E:/AMDDesignTools/2026.1/Vivado/bin',
      [string]$Python='python',
      [string]$CancelFile='',
      [switch]$XelabO0,
      [switch]$XelabDiagnostics,
      [string]$Testbench='verification/pwm_adc/timing_tb.sv',
      [string]$Scope='routed functional PL; ILA/debug hub black boxes; PS clock/reset and AXI transaction sources substituted')
$ErrorActionPreference='Stop'
$axRoot=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))

$runArguments=@((Join-Path $PSScriptRoot 'sdf_runner.py'),
 '--hardware',[IO.Path]::GetFullPath($Hardware),'--run-dir',[IO.Path]::GetFullPath($RunDir),
 '--corner',$Corner,'--vivado-bin',[IO.Path]::GetFullPath($VivadoBin),
 '--testbench',(Join-Path $axRoot $Testbench),'--tool-timeout-ms',"$ToolTimeoutMs",'--scope',$Scope)
if($CancelFile){$runArguments+=@('--cancel-file',[IO.Path]::GetFullPath($CancelFile))}
if($XelabO0){$runArguments+='--xelab-o0'}
if($XelabDiagnostics){$runArguments+='--xelab-diagnostics'}
& $Python @runArguments
if($LASTEXITCODE -ne 0){throw "SDF runner failed (exit $LASTEXITCODE); see $RunDir/summary.json and stage logs"}
