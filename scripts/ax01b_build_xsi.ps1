param([string]$VivadoBin='E:/AMDDesignTools/2026.1/Vivado/bin')
$ErrorActionPreference='Stop'
$axRoot=Split-Path -Parent $PSScriptRoot
$axWork=Join-Path $axRoot '.runtime/ax01b/xsi'
New-Item -ItemType Directory -Force -Path $axWork | Out-Null
$axManifest=Get-Content (Join-Path $axRoot 'generated/legacy_m3_p3/manifest.json') -Raw | ConvertFrom-Json
$axSources=@($axManifest.design_files | ForEach-Object { 'sv work "'+(Join-Path $axRoot ('generated/legacy_m3_p3/'+$_.path)).Replace('\','/')+'"' })
$axSources+=@('axu5ev_foc_frame_top.sv','axu5ev_foc_xsi_top.sv') | ForEach-Object { 'sv work "'+(Join-Path $axRoot ('integration/rtl/'+$_)).Replace('\','/')+'"' }
$axSources | Set-Content (Join-Path $axWork 'sources.prj') -Encoding utf8
Push-Location -LiteralPath $axWork
try {
 & "$VivadoBin/xelab.bat" -prj sources.prj work.axu5ev_foc_xsi_top -dll -s ax01b_p3 -debug off -timescale 1ns/1ps *> build.log
 if($LASTEXITCODE -ne 0){Get-Content build.log -Tail 35;throw 'p3 XSI elaboration failed'}
 Get-Content build.log -Tail 8
} finally {Pop-Location}
