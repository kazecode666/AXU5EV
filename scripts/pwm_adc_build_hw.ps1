param([ValidateSet('base','integrate','synth','audit','validate','build','all','reports')][string]$Stage='all',
      [Parameter(Mandatory=$true)][string]$Output)
$ErrorActionPreference='Stop'
$root=Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $root
if($Stage -in @('base','validate','all') -and (Test-Path -LiteralPath $Output)){throw 'Choose a new output directory'}
$env:MC_PWM='1'
$env:AX03B3_TEST='0'
& "$PSScriptRoot/ax03b3_build_hw.ps1" -Stage $Stage -Output $Output
