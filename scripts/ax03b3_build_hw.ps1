param([ValidateSet('base','integrate','synth','audit','validate','build','all')][string]$Stage='all',
      [string]$Output='.runtime/ax03b3/hardware_real_02')
$ErrorActionPreference='Stop'
$root=Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $root
# Two vendor PS input files only: ASCII paths avoid Vivado Tcl's Windows
# source encoding issue. This is not a second copy of the vendor project.
$vendor=Join-Path $root '.runtime/ax03b2/vendor_ps'
$source=Join-Path $root '资料/course_s2/01_ps_hello/vivado/ps_hello.srcs/sources_1/bd/design_1'
$ip='design_1_zynq_ultra_ps_e_0_0'
if (!(Test-Path -LiteralPath "$vendor/design_1.bd")) {
    New-Item -ItemType Directory -Force -Path "$vendor/ip/$ip" | Out-Null
    Copy-Item -LiteralPath "$source/design_1.bd" -Destination "$vendor/design_1.bd"
    Copy-Item -LiteralPath "$source/ip/$ip/$ip.xci" -Destination "$vendor/ip/$ip/$ip.xci"
}
New-Item -ItemType Directory -Force -Path .runtime/ax03b3 | Out-Null
& 'E:/AMDDesignTools/2026.1/Vivado/bin/vivado.bat' -mode batch `
    -source hardware/axu5ev/motor_control/build.tcl `
    -log "$Output.console.log" -journal "$Output.console.jou" `
    -tclargs $Output $Stage "$vendor/design_1.bd"
if ($LASTEXITCODE -ne 0) {throw "AX03B3 Vivado $Stage failed ($LASTEXITCODE)"}
