from pathlib import Path
import hashlib, json, tarfile
root=Path(__file__).resolve().parent.parent
for entry in json.loads((root/'vendor/manifest.json').read_text()):
    archive=root/'vendor'/entry['archive']
    if hashlib.sha256(archive.read_bytes()).hexdigest()!=entry['sha256']:
        raise ValueError('Dependency checksum mismatch: '+entry['archive'])
    target=root/entry['target'];target.mkdir(parents=True,exist_ok=True)
    with tarfile.open(archive,'r:gz') as t:
        for member in t.getmembers():
            parts=Path(member.name).parts
            if not parts or parts[0]!='package' or '..' in parts or member.issym() or member.islnk():
                raise ValueError('Unsafe vendor member')
            if len(parts)==1:continue
            member.name='/'.join(parts[1:]);t.extract(member,target,filter='data')
    print('Restored '+entry['target'])
