[CmdletBinding()]
param([Parameter(Mandatory=$true)][string]$Hardware,
      [Parameter(Mandatory=$true)][string]$RunDir,
      [ValidateSet('slow','fast')][string]$Corner='slow',
      [string]$VivadoBin='E:/AMDDesignTools/2026.1/Vivado/bin')
$ErrorActionPreference='Stop'
$axRoot=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))

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
$netdir=Join-Path ([IO.Path]::GetFullPath($Hardware)) 'timing_sim'
$sources=@('adc_routed','pwm_routed','clock_routed') | ForEach-Object {Join-Path $netdir ($_.ToString()+'.v')}
$sources+=Join-Path $axRoot 'verification/pwm_adc/timing_tb.sv'
$sources+=Join-Path $VivadoBin '../data/verilog/src/glbl.v'
$compile=Invoke-B2Tool 'xvlog' (@('-sv')+$sources) $RunDir
$option=if($Corner -eq 'slow'){'-sdfmax'}else{'-sdfmin'}
$arguments=@('work.timing_tb','work.glbl','-s','pwm_timing','-debug','typical',
 '-timescale','1ns/1ps','-L','simprims_ver','-L','unisims_ver','-L','secureip',
 '-transport_int_delays','-pulse_r','0','-pulse_int_r','0','-pulse_e','0','-pulse_int_e','0')
foreach($cell in @('adc','pwm','clock')) {
 $sdf=Join-Path $netdir ($cell+'_routed_'+$Corner+'.sdf')
 if(!(Test-Path -LiteralPath $sdf)){throw "Missing actual routed SDF: $sdf"}
 $arguments+=@($option,('/timing_tb/'+$cell+'_dut='+$sdf.Replace('\','/')))
}
$elaborate=Invoke-B2Tool 'xelab' $arguments $RunDir
$simulation=Invoke-B2Tool 'xsim' @('pwm_timing','-runall') $RunDir
$marker=@($simulation -split '\r?\n' | Where-Object {$_ -match '^PWM_SDF_PASS '})
if($marker.Count -ne 1){throw 'Missing SDF test PASS'}
if(($elaborate+$simulation) -match '(?im)(timing violation|\$setuphold|\$recrem|SDF.*(ERROR|WARNING)|not annotated)'){throw 'Review SDF annotation or timing violation'}
$summary=[ordered]@{status='PASS';corner=$Corner;pass_marker=$marker[0];hardware=$Hardware;run_dir=$RunDir;board='NOT_RUN';scope='routed ADC/PWM/MMCM cells; PS/AXI fabric/ILA excluded'}
[IO.File]::WriteAllText((Join-Path $RunDir 'summary.json'),($summary|ConvertTo-Json),[Text.UTF8Encoding]::new($false))
Write-Output $marker[0]
