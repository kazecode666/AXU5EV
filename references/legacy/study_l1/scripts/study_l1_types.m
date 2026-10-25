function t = study_l1_types(mode)
% B1 baseline. B2 only studies numerical effects; resources remain unmeasured.
if mode=="float"
    t.input='double'; t.error='double'; t.coeff='double'; t.work='double';
    t.state='double'; t.sum='double'; t.acc='double'; t.output='double';
elseif mode=="B1"
    t.input='fixdt(1,32,20)'; t.error='fixdt(1,33,20)';
    t.coeff='fixdt(0,32,30)'; t.work='fixdt(1,40,30)';
    t.state='fixdt(1,32,30)'; t.sum='fixdt(1,42,30)';
    t.acc='fixdt(1,44,30)'; t.output='fixdt(1,25,15)';
elseif mode=="B2"
    t.input='fixdt(1,28,16)'; t.error='fixdt(1,29,16)';
    t.coeff='fixdt(0,24,22)'; t.work='fixdt(1,28,18)';
    t.state='fixdt(1,20,18)'; t.sum='fixdt(1,30,18)';
    t.acc='fixdt(1,32,18)'; t.output='fixdt(1,25,15)';
else
    error('StudyL1:TypeMode','Unknown format');
end
end
