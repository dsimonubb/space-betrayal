from pathlib import Path
import hashlib,json,zipfile
root=Path(__file__).resolve().parent.parent
skip={'.git','.godot','.runtime','node_modules','.handoff-work','distribution','builds','editor_data'}
def selected():
    for p in sorted(root.rglob('*')):
        rel=p.relative_to(root)
        if not p.is_file() or any(x in skip for x in rel.parts):continue
        if rel.parts[:2]==('web','evidence'):continue
        if p.name=='MANIFEST.sha256.json':continue
        if p.suffix.lower() in {'.keystore','.jks','.p12','.pfx'} or p.name.startswith('.env'):continue
        yield p
files=list(selected())
manifest={'snapshot':'2026-10-26','files':[{'path':p.relative_to(root).as_posix(),'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in files]}
(root/'MANIFEST.sha256.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf8')
output=root/'distribution';output.mkdir(exist_ok=True)
archive=output/'space-betrayal-developer-2026-10-26.zip'
with zipfile.ZipFile(archive,'w',compression=zipfile.ZIP_DEFLATED,compresslevel=6) as z:
    for p in [*files,root/'MANIFEST.sha256.json']:
        z.write(p,'space-betrayal/'+p.relative_to(root).as_posix())
with zipfile.ZipFile(archive) as z:
    if z.testzip() is not None:raise ValueError('ZIP integrity failed')
    for item in manifest['files']:
        if hashlib.sha256(z.read('space-betrayal/'+item['path'])).hexdigest()!=item['sha256']:raise ValueError('ZIP checksum failed')
print(json.dumps({'archive':str(archive),'files':len(files)+1,'bytes':archive.stat().st_size,'sha256':hashlib.sha256(archive.read_bytes()).hexdigest()}))
