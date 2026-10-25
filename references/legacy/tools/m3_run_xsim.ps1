#Requires -Version 7.0
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$Manifest,
    [string]$RunDir,
    [string]$VivadoBin = 'E:/AMDDesignTools/2026.1/Vivado/bin',
    [ValidateSet('rtl','synth')][string]$Mode = 'rtl',
    [string]$Case = 'default',
    [int]$TimeoutSeconds = 0
)
$ErrorActionPreference = 'Stop'
$repo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
if (-not $RunDir) { $RunDir = Join-Path $repo ('.runtime/m3_' + $Mode + '_' + [guid]::NewGuid().ToString('N')) }
$RunDir = [IO.Path]::GetFullPath($RunDir)
$report = [ordered]@{ stage=$Mode; status='FAIL'; case=$Case; run_dir=$RunDir; evidence=@(); failures=@(); observed_frames=$null; observed_checks=$null; counted_scoreboard=$false; completed=$false; resources_ok=$null; timing_ok=$null; tool_exit_codes=[ordered]@{} }
$canWriteReport=$false
function Within([string]$path,[string]$base) { return $path.Equals($base,[StringComparison]::OrdinalIgnoreCase) -or $path.StartsWith($base.TrimEnd('\','/')+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase) }
function Safe-Argument([string]$value) { if ($value -match '["&|<>^%!\r\n]') { throw 'Unsupported shell metacharacter in tool argument' }; return '"'+$value+'"' }
function Tcl-Quote([string]$value) { return '"'+$value.Replace('\','/').Replace('"','\"').Replace('$','\$').Replace('[','\[').Replace(']','\]')+'"' }
function Write-Json([object]$value,[string]$file) { [IO.File]::WriteAllText($file,($value | ConvertTo-Json -Depth 20)+[Environment]::NewLine,[Text.UTF8Encoding]::new($false)) }
function Tool([string]$name,[string[]]$arguments,[string]$cwd,[int]$seconds,[bool]$allowFailure=$false) {
    $bat = Join-Path $VivadoBin ($name+'.bat')
    if (-not (Test-Path -LiteralPath $bat -PathType Leaf)) { throw "Tool missing: $bat" }
    $words = @((Safe-Argument $bat)) + @($arguments | ForEach-Object { Safe-Argument $_ })
    $psi = [Diagnostics.ProcessStartInfo]::new(); $psi.FileName=$env:ComSpec
    # cmd.exe needs its native /s /c quoting, not .NET ArgumentList backslash quoting.
    $psi.Arguments='/d /s /c "'+($words -join ' ')+'"'
    $psi.WorkingDirectory=$cwd; $psi.UseShellExecute=$false; $psi.CreateNoWindow=$true
    $psi.RedirectStandardOutput=$true; $psi.RedirectStandardError=$true
    $process=[Diagnostics.Process]::new(); $process.StartInfo=$psi
    if (-not $process.Start()) { throw "$name did not start" }
    $stdout=$process.StandardOutput.ReadToEndAsync(); $stderr=$process.StandardError.ReadToEndAsync()
    $finished=$process.WaitForExit($seconds*1000)
    if (-not $finished) { $process.Kill($true); $process.WaitForExit() }
    $output=$stdout.GetAwaiter().GetResult()+[Environment]::NewLine+$stderr.GetAwaiter().GetResult()
    $log=Join-Path $RunDir ($name+'.console.log'); [IO.File]::WriteAllText($log,$output,[Text.UTF8Encoding]::new($false))
    $report.evidence+=@($log)
    if (-not $finished) { throw "$name timeout after $seconds seconds; owned process tree terminated" }
    $report.tool_exit_codes[$name]=$process.ExitCode
    if ($process.ExitCode -ne 0 -and -not $allowFailure) { throw "$name exit=$($process.ExitCode); see $log" }
    if (-not $allowFailure -and $output -match '(?im)^(?:ERROR:|FATAL:|Fatal:|Error:|M3_RTL_FAIL)') { throw "$name reported an error; see $log" }
    return $output
}
try {
    if (-not (Within $RunDir (Join-Path $repo '.runtime'))) { throw 'RunDir must be inside this checkout .runtime' }
    if (Test-Path -LiteralPath $RunDir) {
        if (@(Get-ChildItem -LiteralPath $RunDir -Force).Count -ne 0) { throw 'RunDir already contains evidence; refusing overwrite' }
    } else { New-Item -ItemType Directory -Path $RunDir | Out-Null }
    $canWriteReport=$true
    $manifestPath=[IO.Path]::GetFullPath($Manifest)
    if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) { throw "Manifest missing: $manifestPath" }
    $m=Get-Content -LiteralPath $manifestPath -Raw -Encoding utf8 | ConvertFrom-Json
    if ($m.schema_version -ne 1) { throw 'Manifest schema_version must be 1' }
    $report.manifest=$manifestPath; $report.manifest_sha256=(Get-FileHash -LiteralPath $manifestPath -Algorithm SHA256).Hash.ToLowerInvariant()
    $sourceRoot=if ($m.root_dir) { [string]$m.root_dir } else { Split-Path -Parent $manifestPath }
    if (-not [IO.Path]::IsPathRooted($sourceRoot)) { $sourceRoot=Join-Path (Split-Path -Parent $manifestPath) $sourceRoot }
    $sourceRoot=[IO.Path]::GetFullPath($sourceRoot)
    if (-not (Within $sourceRoot $repo)) { throw 'Manifest root_dir must be in this checkout' }
    foreach ($name in @('dut_top','clock_port')) { if ([string]$m.$name -notmatch '^[A-Za-z_][A-Za-z0-9_$]*$') { throw "Invalid $name" } }
    if ($m.part -ne 'xc7a200tfbg484-2' -or [double]$m.clock_period_ns -ne 20) { throw 'M3 requires xc7a200tfbg484-2 and 20ns' }
    $design=@($m.design_files); $tb=@($m.testbench_files); $data=@($m.data_files)
    if ($design.Count -eq 0 -or $null -eq $design[0]) { throw 'No design_files declared' }
    if ($Mode -eq 'rtl' -and ($tb.Count -eq 0 -or $null -eq $tb[0])) { throw 'No testbench_files declared' }
    $work=Join-Path $RunDir 'work'; New-Item -ItemType Directory -Path $work | Out-Null
    $staged=[ordered]@{}; $orderedDesign=@(); $orderedTb=@()
    foreach ($kind in @('design_files','testbench_files','data_files')) {
        if ($Mode -eq 'synth' -and $kind -eq 'testbench_files') { continue }
        foreach ($entry in @($m.$kind)) {
            if ($null -eq $entry) { continue }
            if ([string]$entry.sha256 -notmatch '^[0-9a-fA-F]{64}$') { throw "Missing/invalid SHA256: $($entry.path)" }
            $path=if ([IO.Path]::IsPathRooted([string]$entry.path)) { [IO.Path]::GetFullPath([string]$entry.path) } else { [IO.Path]::GetFullPath((Join-Path $sourceRoot ([string]$entry.path))) }
            if (-not (Within $path $sourceRoot)) { throw "Artifact escapes manifest root: $($entry.path)" }
            if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Artifact missing: $($entry.path)" }
            $hash=(Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant()
            if ($hash -ne ([string]$entry.sha256).ToLowerInvariant()) { throw "Artifact hash mismatch: $($entry.path)" }
            $relative=[IO.Path]::GetRelativePath($sourceRoot,$path); $dest=Join-Path $work $relative
            [void](Safe-Argument $dest)
            New-Item -ItemType Directory -Path (Split-Path -Parent $dest) -Force | Out-Null
            if (-not $staged.Contains($relative)) { Copy-Item -LiteralPath $path -Destination $dest }
            if ((Get-FileHash -LiteralPath $dest -Algorithm SHA256).Hash.ToLowerInvariant() -ne $hash) { throw 'Staged copy hash mismatch' }
            $staged[$relative]=[ordered]@{source=$path;path=$dest;sha256=$hash;kind=$kind}
            if ($kind -eq 'design_files') { $orderedDesign+=@($dest) }
            if ($kind -eq 'testbench_files') { $orderedTb+=@($dest) }
        }
    }
    Write-Json @($staged.Values) (Join-Path $RunDir 'staged_files.json')
    $report.evidence+=@(Join-Path $RunDir 'staged_files.json')
    $working=$work
    if ($m.runtime_subdir) { $working=[IO.Path]::GetFullPath((Join-Path $work ([string]$m.runtime_subdir))); if (-not (Within $working $work)) { throw 'runtime_subdir escapes staged work' }; New-Item -ItemType Directory -Path $working -Force | Out-Null }
    $includePaths=@(); $defines=@()
    foreach ($dir in @($m.include_dirs)) {
        if ($null -eq $dir) { continue }
        $originalDir=if ([IO.Path]::IsPathRooted([string]$dir)) { [IO.Path]::GetFullPath([string]$dir) } else { [IO.Path]::GetFullPath((Join-Path $sourceRoot ([string]$dir))) }
        if (-not (Within $originalDir $sourceRoot)) { throw 'include_dir escapes manifest root' }
        $inc=[IO.Path]::GetFullPath((Join-Path $work ([IO.Path]::GetRelativePath($sourceRoot,$originalDir))))
        if (-not (Test-Path -LiteralPath $inc -PathType Container)) { throw "Declared include directory absent from staged dependencies: $dir" }
        $includePaths+=@($inc)
    }
    foreach ($define in @($m.defines)) { if ($null -ne $define) { if ([string]$define -notmatch '^[A-Za-z_][A-Za-z0-9_]*(?:=[A-Za-z0-9_+.-]+)?$') { throw 'Invalid macro definition' }; $defines+=@([string]$define) } }
    $seconds=if ($TimeoutSeconds -gt 0) { $TimeoutSeconds } elseif ($Mode -eq 'synth') { 1800 } elseif ($m.simulation.timeout_seconds) { [int]$m.simulation.timeout_seconds } else { 600 }
    if ($seconds -lt 1 -or $seconds -gt 14400) { throw 'Timeout must be 1..14400 seconds per tool' }
    if ($Mode -eq 'synth') {
        $out=Join-Path $RunDir 'synth'; $script=Join-Path $PSScriptRoot 'm3_synth_foc_ooc.tcl'
        if (-not (Test-Path -LiteralPath $script -PathType Leaf)) { throw 'OOC synthesis script missing' }
        $config=Join-Path $RunDir 'manifest_ooc.tcl'
        $lines=@('# Derived only from hash-verified JSON manifest; no algorithm commands.',('set m3_root '+(Tcl-Quote $working)),('set m3_top '+(Tcl-Quote ([string]$m.dut_top))),('set m3_clock_port '+(Tcl-Quote ([string]$m.clock_port))),('set m3_part '+(Tcl-Quote ([string]$m.part))),('set m3_clock_period_ns '+([double]$m.clock_period_ns).ToString([Globalization.CultureInfo]::InvariantCulture)),('set m3_manifest_sha256 '+(Tcl-Quote $report.manifest_sha256)),'set m3_hashes_verified 1',('set m3_design_files [list '+(($orderedDesign | ForEach-Object { Tcl-Quote $_ }) -join ' ')+']'))
        $lines+=@(('set m3_include_dirs [list '+(($includePaths | ForEach-Object { Tcl-Quote $_ }) -join ' ')+']'),('set m3_defines [list '+(($defines | ForEach-Object { Tcl-Quote $_ }) -join ' ')+']'))
        [IO.File]::WriteAllLines($config,$lines,[Text.UTF8Encoding]::new($false))
        $output=Tool 'vivado' @('-mode','batch','-nojournal','-log',(Join-Path $RunDir 'vivado.log'),'-source',$script,'-tclargs',$config,$out) $working $seconds $true
        $resultFile=Join-Path $out 'ooc_result.json'
        if (-not (Test-Path -LiteralPath $resultFile -PathType Leaf)) { throw 'OOC result missing' }
        $s=Get-Content -LiteralPath $resultFile -Raw -Encoding utf8 | ConvertFrom-Json
        $report.completed=[bool]$s.completed; $report.resources_ok=[bool]$s.resources_ok; $report.timing_ok=[bool]$s.timing_ok
        $report.evidence+=@($resultFile)
        if ($report.tool_exit_codes['vivado'] -ne 0 -or -not ($s.completed -and $s.resources_ok -and $s.timing_ok)) { throw 'OOC completed/resource/timing checks not all satisfied' }
    } else {
        if ([string]$m.tb_top -notmatch '^[A-Za-z_][A-Za-z0-9_$]*$') { throw 'Invalid tb_top' }
        $argsFile=Join-Path $working 'm3_compile.args'; $argsLines=@('--sv','--work work')
        foreach ($inc in $includePaths) { $argsLines+=@('-i '+(Safe-Argument $inc)) }
        foreach ($define in $defines) { $argsLines+=@('-d '+$define) }
        $argsLines+=@(($orderedDesign+$orderedTb) | ForEach-Object { Safe-Argument $_ })
        [IO.File]::WriteAllLines($argsFile,$argsLines,[Text.UTF8Encoding]::new($false))
        [void](Tool 'xvlog' @('-f',$argsFile) $working $seconds)
        $elab=@('-debug','typical',[string]$m.tb_top,'-s','m3_snapshot')
        foreach ($lib in @($m.elab_libraries)) { if ($null -ne $lib) { if ([string]$lib -notmatch '^[A-Za-z_][A-Za-z0-9_]*$') { throw 'Invalid simulator library' }; $elab+=@('-L',[string]$lib) } }
        [void](Tool 'xelab' $elab $working $seconds)
        $simArgs=@('m3_snapshot','-runall')
        $plusKeys=[Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
        foreach ($arg in @($m.simulation.plusargs)) {
            if ($null -eq $arg) { continue }
            $value=([string]$arg).TrimStart('+')
            if ($value -notmatch '^([A-Za-z_][A-Za-z0-9_]*)=(.*)$') { throw 'plusargs must be key=value strings' }
            if (-not $plusKeys.Add($Matches[1])) { throw 'Duplicate simulation plusarg key' }
            [void](Safe-Argument $value); $simArgs+=@('-testplusarg',$value)
        }
        if ($m.simulation.plusarg_files) { foreach ($property in $m.simulation.plusarg_files.PSObject.Properties) {
            if ($property.Name -notmatch '^[A-Za-z_][A-Za-z0-9_]*$' -or -not $plusKeys.Add($property.Name)) { throw 'Invalid/duplicate input-file plusarg key' }
            $inputPath=if ([IO.Path]::IsPathRooted([string]$property.Value)) { [IO.Path]::GetFullPath([string]$property.Value) } else { [IO.Path]::GetFullPath((Join-Path $sourceRoot ([string]$property.Value))) }
            $record=@($staged.Values | Where-Object { $_.source.Equals($inputPath,[StringComparison]::OrdinalIgnoreCase) })
            if ($record.Count -ne 1 -or $record[0].kind -ne 'data_files') { throw 'Input-file plusarg must reference a declared SHA256-validated data file' }
            # xsim forwards these through Tcl: forward slashes preserve Windows paths.
            $simArgs+=@('-testplusarg',($property.Name+'='+$record[0].path.Replace('\','/')))
        } }
        if ($m.simulation.plusarg_outputs) { foreach ($property in $m.simulation.plusarg_outputs.PSObject.Properties) {
            if ($property.Name -notmatch '^[A-Za-z_][A-Za-z0-9_]*$' -or -not $plusKeys.Add($property.Name)) { throw 'Invalid/duplicate output-file plusarg key' }
            $outputPath=if ([IO.Path]::IsPathRooted([string]$property.Value)) { [IO.Path]::GetFullPath([string]$property.Value) } else { [IO.Path]::GetFullPath((Join-Path $RunDir ([string]$property.Value))) }
            if (-not (Within $outputPath $RunDir) -or $outputPath.Equals((Join-Path $RunDir 'result.json'),[StringComparison]::OrdinalIgnoreCase) -or (Test-Path -LiteralPath $outputPath)) { throw 'Output-file plusarg must be a new nonreserved path inside RunDir' }
            New-Item -ItemType Directory -Path (Split-Path -Parent $outputPath) -Force | Out-Null
            $simArgs+=@('-testplusarg',($property.Name+'='+$outputPath.Replace('\','/')))
        } }
        $output=Tool 'xsim' $simArgs $working $seconds
        if ($m.simulation.failure_regex -and $output -match [string]$m.simulation.failure_regex) { throw 'Simulation failure pattern matched' }
        if ($m.simulation.kind -eq 'generated_ordinary') {
            if (-not $m.simulation.success_regex) { throw 'Ordinary generated TB requires an explicit observed success_regex' }
            if ($output -notmatch [string]$m.simulation.success_regex) { throw 'Ordinary generated TB success marker absent' }
            $report.verification_kind='generated_ordinary_marker_only'; $report.counted_scoreboard=$false
        } else {
            $pattern=if ($m.simulation.success_regex) { [string]$m.simulation.success_regex } else { 'M3_RTL_PASS\s+frames=(?<frames>\d+)\s+checks=(?<checks>\d+)\s+bit_mismatch=(?<bits>\d+)\s+protocol_errors=(?<protocol>\d+)\s+deadline_errors=(?<deadline>\d+)' }
            $matchesFound=[regex]::Matches($output,$pattern)
            if ($matchesFound.Count -ne 1) { throw 'Expected exactly one counted simulation success marker' }
            $hit=$matchesFound[0]
            foreach ($key in @('frames','checks','bits','protocol','deadline')) { if (-not $hit.Groups[$key].Success) { throw "Success regex must expose named group $key" } }
            $report.observed_frames=[long]$hit.Groups['frames'].Value; $report.observed_checks=[long]$hit.Groups['checks'].Value
            if ($report.observed_frames -lt 1 -or $report.observed_checks -lt 1) { throw 'Zero frames/checks cannot PASS' }
            if ([long]$m.simulation.expected_frames -lt 1 -or [long]$m.simulation.expected_checks -lt 1) { throw 'Expected nonzero frame/check counts are required' }
            if ($report.observed_frames -ne [long]$m.simulation.expected_frames -or $report.observed_checks -ne [long]$m.simulation.expected_checks) { throw 'Observed frame/check counts do not match manifest' }
            foreach ($key in @('bits','protocol','deadline')) { if ([long]$hit.Groups[$key].Value -ne 0) { throw "Nonzero $key errors in success marker" } }
            $report.counted_scoreboard=$true; $report.verification_kind='independent_counted_scoreboard'
        }
        $report.completed=$true
    }
    $report.status='PASS'; Write-Json $report (Join-Path $RunDir 'result.json')
    Write-Output "M3_TOOL_PASS mode=$Mode case=$Case result=$(Join-Path $RunDir 'result.json')"
    exit 0
} catch {
    $report.failures+=@($_.Exception.Message)
    if ($canWriteReport -and (Within $RunDir (Join-Path $repo '.runtime')) -and (Test-Path -LiteralPath $RunDir -PathType Container) -and -not (Test-Path -LiteralPath (Join-Path $RunDir 'result.json'))) { Write-Json $report (Join-Path $RunDir 'result.json') }
    Write-Error -Message $_.Exception.Message -ErrorAction Continue
    exit 2
}
