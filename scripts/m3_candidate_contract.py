"""Fail closed on candidate identity, scheduled phase, and state-event drift."""
import argparse
import json
from pathlib import Path

def validate(contract, identity):
    for key in ('candidate_id','configuration_sha256'):
        if contract.get(key)!=identity.get(key) or not contract.get(key):
            raise ValueError('candidate contract identity mismatch: '+key)
    phase=contract.get('output_phase_cycles')
    if not isinstance(phase,int) or not 0<phase<=2498:
        raise ValueError('candidate phase exceeds unchanged PWM budget')
    if 'output_phase_cycles' in identity and phase!=identity['output_phase_cycles']:
        raise ValueError('candidate output schedule mismatch')
    events=contract.get('state_events',{})
    allowed=[{'pi_consume':5000,'pi_commit':5000,'aw_commit':1},{'pi_consume':5000,'pi_commit':1,'aw_commit':1}]
    if events not in allowed:
        raise ValueError('missing or changed state mapping requires explicit requalification')
    if events['pi_commit']==1:
        if contract.get('pi_next_signals')!={'d':'u_Id.x_d_z_out1_1','q':'u_Iq.x_q_z_out1_1'} or not contract.get('pi_commit_evidence'):
            raise ValueError('next-frame PI commit requires explicit generated D-input qualification')
    supported={'x_d_old':'u_Id.x_d_z_out1','x_q_old':'u_Iq.x_q_z_out1',
               'aw_d_old':'dq_voltage_limiter_du_d_z','aw_q_old':'dq_voltage_limiter_du_q_z'}
    if contract.get('state_mapping')!=supported:
        raise ValueError('missing or unqualified state signal mapping')
    if contract.get('frame_cycles')!=5000 or not contract.get('schedule_evidence'):
        raise ValueError('missing generated schedule or frame contract')
    return contract

def main():
    p=argparse.ArgumentParser();p.add_argument('--manifest',required=True);p.add_argument('--contract',required=True)
    a=p.parse_args();m=json.loads(Path(a.manifest).read_text(encoding='utf-8-sig'))
    c=json.loads(Path(a.contract).read_text(encoding='utf-8-sig'))
    import hashlib
    if hashlib.sha256(Path(a.contract).read_bytes()).hexdigest()!=m['candidate_contract']['sha256']:
        raise ValueError('candidate contract hash mismatch')
    validate(c,{'candidate_id':m['candidate_id'],'configuration_sha256':m['build_identity']['configuration_sha256']})
    print(json.dumps(c))
if __name__=='__main__':main()
