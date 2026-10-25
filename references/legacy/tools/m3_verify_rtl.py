"""Run or consume hash-matched independent FOC xsim evidence; failures stay failures."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import sys
import uuid

ROOT = Path(__file__).resolve().parents[1]


def read(p):
    return json.loads(p.read_text(encoding='utf-8-sig'))


def sha(p):
    return hashlib.sha256(p.read_bytes()).hexdigest()


def validate_files(m, file):
    root = Path(m.get('root_dir', '.'))
    if not root.is_absolute():
        root = file.parent / root
    for kind in ('design_files', 'testbench_files', 'data_files'):
        for entry in m[kind]:
            p = (root / entry['path']).resolve()
            assert p.is_relative_to(root.resolve()) and sha(p) == entry['sha256']


def match_existing(run, manifest, golden, mode):
    for file in sorted(run.glob('*/result.json')):
        r = read(file)
        if not r.get('counted_scoreboard') and r.get('status') == 'PASS':
            continue
        mf = Path(r.get('manifest', ''))
        score = file.parent / 'scoreboard.json'
        if not mf.is_file() or not score.is_file():
            continue
        if mode in ('bit_negative', 'cycle_negative') and not (file.parent / 'wrapper_exit.json').is_file():
            continue
        m = read(mf)
        i = m.get('independent_scoreboard', {})
        if (i.get('mode') == mode and i.get('source_manifest_sha256') == sha(manifest)
                and i.get('source_golden_sha256') == sha(golden)
                and any(e['sha256'] == sha(ROOT / 'verification/m3_foc/m3_foc_scoreboard.sv')
                        for e in m['testbench_files'])):
            assert r['manifest_sha256'] == sha(mf)
            validate_files(m, mf)
            return file, m, r, read(score), True
    return None


def execute(run, manifest, golden, name, mode):
    existing = match_existing(run, manifest, golden, mode)
    if existing:
        return existing
    label = name + '_' + mode + '_' + uuid.uuid4().hex[:10]
    mf = run / (label + '_stage') / 'manifest.json'
    cmd = [sys.executable, str(ROOT / 'scripts/m3_build_scoreboard.py'),
           '--manifest', str(manifest), '--golden', str(golden), '--out', str(mf),
           '--case', name, '--mode', mode]
    subprocess.run(cmd, check=True)
    folder = run / (label + '_run')
    code = subprocess.run(['pwsh', '-NoProfile', '-File', str(ROOT / 'scripts/m3_run_xsim.ps1'),
                           '-Manifest', str(mf), '-RunDir', str(folder), '-Case', label]).returncode
    with (folder / 'wrapper_exit.json').open('x', encoding='utf8') as f:
        json.dump({'exit_code': code, 'scope': 'PowerShell strict xsim runner; native xsim may exit0 after $fatal'}, f)
    file = folder / 'result.json'
    assert file.is_file() and (folder / 'scoreboard.json').is_file(), f'Missing counted evidence exit{code}'
    return file, read(mf), read(file), read(folder / 'scoreboard.json'), False


def verify(item, mode):
    file, m, tool, score, consumed = item
    for key in ('state_mismatch', 'xz_count', 'protocol_errors', 'deadline_errors'):
        assert score[key] == 0, f'{key}={score[key]}'
    assert score['expected_frames'] == score['observed_frames'] == m['simulation']['expected_frames'] > 0
    assert score['checks'] == m['simulation']['expected_checks'] > 0
    assert score['output_phase'] == m['independent_scoreboard']['output_post_edge_phase'] and score['frame_clocks'] == 5000
    negative = mode in ('bit_negative', 'cycle_negative')
    if negative:
        assert tool['status'] == 'FAIL' and score['status'] == 'FAIL' and score['bit_mismatch'] == 1
        assert read(file.parent / 'wrapper_exit.json')['exit_code'] != 0, 'Expected actual nonzero strict runner exit'
        assert 'M3_RTL_FAIL' in (file.parent / 'xsim.console.log').read_text(encoding='utf-8-sig')
        if mode == 'cycle_negative':
            assert score['early_checks'] == 3 and score['early_mismatch'] == 1
    else:
        assert tool['status'] == score['status'] == 'PASS' and score['bit_mismatch'] == 0
        assert tool['counted_scoreboard'] is True
        assert score['max_wall_latency_clocks'] + 1 + 1 <= 2500, 'Output commit and reserved margin exceed deadline'
    return {'mode': mode, 'status': 'PASS', 'negative_rejected': negative,
            'tool_status': tool['status'], 'evidence': str(file),
            'scoreboard': str(file.parent / 'scoreboard.json'),
            'consumed_existing_hash_matched_evidence': consumed,
            'observed_frames': score['observed_frames'], 'checks': score['checks'],
            'output_commit_register_clocks': 1, 'minimum_submission_margin_clocks': 1,
            'submission_margin_clocks': 2500 - score['max_wall_latency_clocks'] - 1,
            'ce_pause_scope': 'diagnostic wall time, not normal deadline proof' if mode == 'ce' else None}


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--run-dir', type=Path, required=True)
    p.add_argument('--probe-only', action='store_true',help='R2 directed17 only; never a complete R3 verdict')
    a = p.parse_args()
    run = a.run_dir.resolve()
    manifest = run / 'manifest.json'
    candidates = []
    for file in run.glob('model_result_*.json'):
        data = read(file)
        if (a.probe_only or data.get('complete_suites', True)) and len(data.get('cases', [])) >= (1 if a.probe_only else 3):
            candidates.append((file, data))
    assert candidates, 'Missing complete source/gm case exports'
    _, model = max(candidates, key=lambda x: x[0].stat().st_mtime_ns)
    by_name = {c['name']: c for c in model['cases']}
    result = {'stage': 'rtl', 'status': 'PASS', 'run_dir': str(run), 'evidence': [],
              'failures': [], 'manifest_sha256': sha(manifest), 'model_status': model['status'], 'cases': [],'complete_suites':not a.probe_only}
    suites=[('directed_probe', ['normal', 'ce', 'reset', 'bit_negative', 'cycle_negative'], 17)]
    if not a.probe_only:suites.extend([('boundary_random', ['normal'], 1024), ('actual_prefix', ['normal'], 1536)])
    for name, modes, minimum in suites:
        case = by_name[name]
        assert case['samples'] >= minimum
        golden = Path(case['folder']) / 'source_hex.csv'
        for mode in modes:
            try:
                r = verify(execute(run, manifest, golden, name, mode), mode)
                r['name'] = name
                result['cases'].append(r)
                result['evidence'].append(r['evidence'])
            except Exception as error:
                result['status'] = 'FAIL'
                result['failures'].append({'name': name, 'mode': mode, 'message': str(error)})
                if a.probe_only:
                    result['stopped_after_first_failure']=True
                    break
    output = run / ('rtl_probe_result.json' if a.probe_only else 'rtl_result.json')
    with output.open('x', encoding='utf8') as f:
        json.dump(result, f, ensure_ascii=False, indent=2)
        f.write('\n')
    print('M3_RTL_STAGE', result['status'], output)
    return 0 if result['status'] == 'PASS' else 1


if __name__ == '__main__':
    raise SystemExit(main())
