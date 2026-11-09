[CmdletBinding()]
param([string]$RunDir,[string]$VivadoBin='E:/AMDDesignTools/2026.1/Vivado/bin')
$ErrorActionPreference='Stop'
$axRoot=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
if(-not $RunDir){$RunDir=Join-Path $axRoot ('.runtime/ax03b2/interface_'+[guid]::NewGuid().ToString('N'))}
$RunDir=[IO.Path]::GetFullPath($RunDir)
if(Test-Path -LiteralPath $RunDir){throw 'RunDir exists; choose a new directory to preserve previous results'}
New-Item -ItemType Directory -Path $RunDir -Force | Out-Null
function Quote-B2([string]$value){
 if($value -match '["&|<>^%!\r\n]'){throw 'Unsupported tool argument metacharacter'}
 return '"'+$value+'"'
}
function Invoke-B2Tool([string]$name,[string[]]$Arguments,[string]$Directory){
 $bat=Join-Path $VivadoBin ($name+'.bat')
 if(-not (Test-Path -LiteralPath $bat)){throw "Missing tool: $bat"}
 $words=@((Quote-B2 $bat))+@($Arguments|ForEach-Object{Quote-B2 $_})
 $psi=[Diagnostics.ProcessStartInfo]::new()
 $psi.FileName=$env:ComSpec;$psi.Arguments='/d /s /c "'+($words -join ' ')+'"'
 $psi.WorkingDirectory=$Directory;$psi.UseShellExecute=$false;$psi.CreateNoWindow=$true
 $psi.RedirectStandardOutput=$true;$psi.RedirectStandardError=$true
 $process=[Diagnostics.Process]::new();$process.StartInfo=$psi
 if(-not $process.Start()){throw "$name failed to start"}
 $stdout=$process.StandardOutput.ReadToEndAsync();$stderr=$process.StandardError.ReadToEndAsync()
 $finished=$process.WaitForExit(300000)
 if(-not $finished){$process.Kill();throw "$name timed out"}
 $output=$stdout.GetAwaiter().GetResult()+[Environment]::NewLine+$stderr.GetAwaiter().GetResult()
 [IO.File]::WriteAllText((Join-Path $Directory ($name+'.console.log')),$output,[Text.UTF8Encoding]::new($false))
 if($process.ExitCode -ne 0 -or $output -match '(?im)^(ERROR:|FATAL:|Fatal:|Error:).*'){
  Write-Output ($output -split '\r?\n' | Select-Object -Last 20)
  throw "$name failed; see $Directory"
 }
 return $output
}
# Compile only this new physical interface and its two unchanged B1 dependencies.
$sources=@('hardware/axu5ev/motor_control/rtl/adc/ax03b1_adc_receiver.sv',
 'hardware/axu5ev/motor_control/rtl/axi/ax03b1_snapshot_axi.sv',
 'integration/rtl/ax03b2/ax03b2_adc_observer.sv',
 'verification/ax03b2/adc_interface_tb.sv') | ForEach-Object {Join-Path $axRoot $_}
$compile=Invoke-B2Tool 'xvlog' (@('-sv')+$sources) $RunDir
$elaborate=Invoke-B2Tool 'xelab' @('work.ax03b2_adc_interface_tb','-s','b2_interface','-debug','off','-timescale','1ns/1ps') $RunDir
$simulation=Invoke-B2Tool 'xsim' @('b2_interface','-runall') $RunDir
$marker=@($simulation -split '\r?\n' | Where-Object {$_ -match '^AX03B2_ADC_INTERFACE_PASS '})
if($marker.Count -ne 1){throw 'New interface simulation did not produce its PASS marker'}
$summary=[ordered]@{status='PASS';scope='NEW_ADC_PHYSICAL_INTERFACE_RTL_ONLY';pass_marker=$marker[0];run_dir=$RunDir;board='NOT_RUN';old_pr24_b1_regression='NOT_RUN'}
[IO.File]::WriteAllText((Join-Path $RunDir 'summary.json'),($summary|ConvertTo-Json -Depth 5),[Text.UTF8Encoding]::new($false))
Write-Output $marker[0]
Write-Output ('AX03B2_RTL_PASS '+(Join-Path $RunDir 'summary.json'))
