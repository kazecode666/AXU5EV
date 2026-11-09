param([Parameter(Mandatory=$true)][string]$RunDir,
 [Parameter(Mandatory=$true)][string]$Vectors,
 [string]$VivadoBin='E:/AMDDesignTools/2026.1/Vivado/bin')
$ErrorActionPreference='Stop'
$repo=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$RunDir=[IO.Path]::GetFullPath($RunDir)
$Vectors=[IO.Path]::GetFullPath($Vectors)
if(Test-Path -LiteralPath $RunDir){throw 'Choose a new result directory'}
New-Item -ItemType Directory -Path $RunDir | Out-Null
function Invoke-AngleTool([string]$name,[string[]]$words){
 $quoted=@((Join-Path $VivadoBin ($name+'.bat')))+$words|ForEach-Object{'"'+$_+'"'}
 $psi=[Diagnostics.ProcessStartInfo]::new();$psi.FileName=$env:ComSpec
 $psi.Arguments='/d /s /c "'+($quoted -join ' ')+'"';$psi.WorkingDirectory=$RunDir
 $psi.UseShellExecute=$false;$psi.CreateNoWindow=$true
 $psi.RedirectStandardOutput=$true;$psi.RedirectStandardError=$true
 $p=[Diagnostics.Process]::new();$p.StartInfo=$psi;$null=$p.Start()
 $o=$p.StandardOutput.ReadToEndAsync();$e=$p.StandardError.ReadToEndAsync()
 if(!$p.WaitForExit(180000)){$p.Kill();throw "$name timeout"}
 $log=$o.GetAwaiter().GetResult()+$e.GetAwaiter().GetResult()
 [IO.File]::WriteAllText((Join-Path $RunDir "$name.log"),$log)
 if($p.ExitCode -ne 0 -or $log -match '(?im)^(ERROR:|FATAL:|Fatal:|Error:)'){throw "$name failed; inspect $RunDir"}
 return $log
}
$sources=@('generated/encoder/AXU5EV_Encoder_Angle_HDL/Electric_Angle_Core.sv',
 'generated/encoder/AXU5EV_Encoder_Angle_HDL/Encoder_Angle.sv','verification/encoder_feedback/angle_tb.sv') |
 ForEach-Object{Join-Path $repo $_}
$null=Invoke-AngleTool 'xvlog' (@('-sv')+$sources)
$null=Invoke-AngleTool 'xelab' @('work.angle_tb','-s','angle','-debug','off','-timescale','1ns/1ps')
$log=Invoke-AngleTool 'xsim' @('angle','-testplusarg',('VECTORS='+$Vectors.Replace('\','/')),'-runall')
$pass=@($log -split '\r?\n'|Where-Object{$_ -match '^ANGLE_PASS '})
if($pass.Count -ne 1){throw 'Angle RTL did not PASS'}
[ordered]@{status='PASS';pass_marker=$pass[0];vectors=$Vectors;board='NOT_RUN'} |
 ConvertTo-Json|Set-Content -LiteralPath (Join-Path $RunDir 'summary.json')
$pass[0]
