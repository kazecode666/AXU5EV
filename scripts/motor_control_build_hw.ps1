param([ValidateSet('all','build','reports','sdf')][string]$Stage='all',
      [Parameter(Mandatory=$true)][string]$Output)
$ErrorActionPreference='Stop'
$hadAuto=Test-Path Env:MC_AUTO
$savedAuto=$env:MC_AUTO
try {
 $env:MC_AUTO='1'
 & "$PSScriptRoot/encoder_feedback_build_hw.ps1" -Stage $Stage -Output $Output
} finally {
 if($hadAuto){$env:MC_AUTO=$savedAuto}else{$env:MC_AUTO=$null}
}
