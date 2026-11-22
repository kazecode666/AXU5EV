param([ValidateSet('all','base','integrate','synth','audit','validate','build','reports','sdf')][string]$Stage='all',
      [Parameter(Mandatory=$true)][string]$Output,
      [ValidateSet('Legacy','SELFTEST','REAL')][string]$Profile='Legacy',
      [switch]$Ax05aObservation)
$ErrorActionPreference='Stop'
$savedEnvironment=@{}
foreach($name in @('MC_AUTO','MC_PWM','MC_ENCODER','MC_AX04B','MC_AX05A','AX03B3_TEST')){
 $savedEnvironment[$name]=[Environment]::GetEnvironmentVariable($name,'Process')
}
try {
 $env:MC_AUTO='1'
 $env:MC_AX05A=if($Ax05aObservation){'1'}else{$null}
 if($Profile -eq 'Legacy'){
  if($Ax05aObservation){throw 'AX05A observation requires an AX04B profile'}
  $env:MC_AX04B=$null
  & "$PSScriptRoot/encoder_feedback_build_hw.ps1" -Stage $Stage -Output $Output
 } else {
  if($Stage -eq 'sdf'){throw 'AX04B runs implementation and STA/CDC only'}
  $root=Split-Path -Parent $PSScriptRoot
  if([IO.Path]::IsPathRooted($Output)){
   $candidate=[IO.Path]::GetFullPath($Output)
  } else {
   $candidate=[IO.Path]::GetFullPath((Join-Path $root $Output))
  }
  $candidateRoot=[IO.Path]::GetFullPath((Join-Path $root '.runtime/experiment/ax04b'))
  if(!$candidate.StartsWith($candidateRoot + [IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)){
   throw "Choose an AX04B hardware output below $candidateRoot"
  }
  if($Stage -in @('all','base','validate') -and (Test-Path -LiteralPath $candidate)){
   throw 'Choose a new AX04B hardware output directory'
  }
  New-Item -ItemType Directory -Force -Path (Split-Path -Parent $candidate) | Out-Null
  $env:MC_AX04B=$Profile.ToUpperInvariant()
  $env:MC_PWM='1'
  $env:MC_ENCODER='1'
  $env:AX03B3_TEST=if($Profile -eq 'SELFTEST'){'1'}else{'0'}
  # Invoke the common Vivado flow directly to avoid the legacy SDF export.
  & "$PSScriptRoot/ax03b3_build_hw.ps1" -Stage $Stage -Output $candidate
 }
} finally {
 foreach($name in $savedEnvironment.Keys){
  [Environment]::SetEnvironmentVariable($name,$savedEnvironment[$name],'Process')
 }
}
