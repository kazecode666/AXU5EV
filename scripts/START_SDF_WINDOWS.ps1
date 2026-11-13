[CmdletBinding()]
param(
 [Parameter(Mandatory=$true)][string]$PackageRoot,
 [Parameter(Mandatory=$true)][string]$ResultRoot,
 [string]$VivadoBin='',
 [string]$Python='python',
 [ValidateSet('slow','fast')][string]$Corner='slow',
 [ValidateRange(1,2147483647)][int]$ToolTimeoutMs=3600000,
 [string]$SlowSummary='',
 [switch]$DryRun
)
$ErrorActionPreference='Stop'
$package=[IO.Path]::GetFullPath($PackageRoot)
$results=[IO.Path]::GetFullPath($ResultRoot)
if(-not $VivadoBin){
 if($env:XILINX_VIVADO){$VivadoBin=Join-Path $env:XILINX_VIVADO 'bin'}
 else{$found=Get-Command xelab.bat -ErrorAction SilentlyContinue;if($found){$VivadoBin=Split-Path $found.Source}}
}
if(-not $VivadoBin){throw 'Provide -VivadoBin for your existing Vivado 2026.1 bin directory'}
$VivadoBin=[IO.Path]::GetFullPath($VivadoBin)
$hardware=Join-Path $package 'inputs/hardware_02'
$testbench=Join-Path $package 'verification/motor_control/timing_tb.sv'
if($Corner -eq 'fast' -and -not $DryRun){
 if(-not $SlowSummary){throw 'fast requires -SlowSummary from the successful slow/max run'}
 $slow=Get-Content -LiteralPath $SlowSummary -Raw | ConvertFrom-Json
 if($slow.status -ne 'PASS' -or $slow.corner -ne 'slow' -or -not $slow.xelab_o0 -or
    [IO.Path]::GetFullPath($slow.hardware) -ne [IO.Path]::GetFullPath($hardware)){
  throw 'fast rejected: slow must be PASS with O0 and the same hardware input directory'
 }
}
$runName=if($DryRun){'dry_'+$Corner+'_01'}else{$Corner+'_01'}
$run=Join-Path $results $runName
$checkLog=Join-Path $results ($runName+'_input_check.json')
if((Test-Path -LiteralPath $run) -or (Test-Path -LiteralPath $checkLog)){throw 'Result paths exist; choose a new ResultRoot; preserve old results'}
New-Item -ItemType Directory -Path $results -Force | Out-Null
$check=@(& $Python (Join-Path $package 'scripts/motor_control_sdf_inputs.py') --root $package 2>&1)
$checkExit=$LASTEXITCODE
[IO.File]::WriteAllText($checkLog,($check -join [Environment]::NewLine),[Text.UTF8Encoding]::new($false))
if($checkExit -ne 0){throw "Input integrity check failed; see $checkLog"}
$arguments=@((Join-Path $PSScriptRoot 'sdf_runner.py'),
 '--hardware',$hardware,'--testbench',$testbench,'--run-dir',$run,'--vivado-bin',$VivadoBin,
 '--corner',$Corner,'--tool-timeout-ms',"$ToolTimeoutMs",'--xelab-o0',
 '--cancel-file',(Join-Path $results ('CANCEL_'+$Corner+'_01')))
# Keep default verbosity: verbose-1 INFO instance paths can contain 'error_register'
# and collide with the unchanged strict annotation matcher. Warnings/checks stay on.
if($DryRun){$arguments+='--dry-run'}
& $Python @arguments
if($LASTEXITCODE -ne 0){throw "SDF did not pass; preserve $run and report summary/process/native logs"}
