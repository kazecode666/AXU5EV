param([ValidateSet('all','build','reports','sdf')][string]$Stage='all',
      [Parameter(Mandatory=$true)][string]$Output)
$ErrorActionPreference='Stop'
$hadEncoder=Test-Path Env:MC_ENCODER
$originalEncoder=$env:MC_ENCODER
try {
 $env:MC_ENCODER='1'
 & "$PSScriptRoot/pwm_adc_build_hw.ps1" -Stage $Stage -Output $Output
} finally {
 if($hadEncoder){$env:MC_ENCODER=$originalEncoder}else{$env:MC_ENCODER=$null}
}
