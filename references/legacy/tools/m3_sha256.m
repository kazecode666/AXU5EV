function value=m3_sha256(file)
% Python标准库按原始字节计算；R2026b本机没有Java，不新增JRE依赖。
helper=fullfile(fileparts(mfilename('fullpath')),'m3_artifact_identity.py');
[code,console]=system(sprintf('python "%s" hash --path "%s"',helper,file));
assert(code==0,'M3:HASH_FILE','Missing or unreadable %s.',file);
result=jsondecode(console);value=result.sha256;
end
