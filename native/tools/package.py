import hashlib
import argparse
import json
import pathlib
import shutil
import zipfile

parser = argparse.ArgumentParser()
parser.add_argument("--version", default="0.2.0")
version = parser.parse_args().version

root = pathlib.Path(__file__).resolve().parent.parent
out = root / "deliverables"
out.mkdir(exist_ok=True)
pc = root / "builds/Windows"
for name in ["README.md", "THIRD_PARTY_NOTICES.md", "GODOT_COPYRIGHT.txt"]:
    shutil.copy2(root / name, pc / name)
(pc / "PORNESTE-PC.cmd").write_text(
    '@echo off\nsetlocal\nif not exist "%~dp0Data" mkdir "%~dp0Data"\n'
    'set "APPDATA=%~dp0Data"\nset "LOCALAPPDATA=%~dp0Data"\n'
    'start "" "%~dp0SpaceBetrayal.exe" --log-file "%~dp0Data\\play.log"\n', encoding="ascii")
with zipfile.ZipFile(out / f"SpaceBetrayal-PC-{version}.zip", "w", zipfile.ZIP_DEFLATED, compresslevel=6) as archive:
    for path in sorted(pc.iterdir()):
        if path.name in {"SpaceBetrayal.exe", "SpaceBetrayal.pck", "README.md", "PORNESTE-PC.cmd", "THIRD_PARTY_NOTICES.md", "GODOT_COPYRIGHT.txt"}:
            archive.write(path, "SpaceBetrayal-PC/" + path.name)
with zipfile.ZipFile(out / f"SpaceBetrayal-PC-{version}.zip") as archive:
    if archive.testzip() is not None:
        raise RuntimeError("PC archive failed CRC")
shutil.copy2(root / f"builds/Android/SpaceBetrayal-{version}.apk", out / f"SpaceBetrayal-Android-{version}.apk")
with zipfile.ZipFile(out / f"SpaceBetrayal-Source-{version}.zip", "w", zipfile.ZIP_DEFLATED, compresslevel=6) as archive:
    for name in ["README.md", "THIRD_PARTY_NOTICES.md", "GODOT_COPYRIGHT.txt", "project.godot", "main.tscn", "icon.svg", "export_presets.cfg"]:
        archive.write(root / name, "SpaceBetrayal/" + name)
    for folder in ["scripts", "tests", "Docs", "artifacts"]:
        for path in sorted((root / folder).rglob("*")):
            if path.is_file():
                archive.write(path, "SpaceBetrayal/" + path.relative_to(root).as_posix())
    for name in ["fetch_templates.py", "build.ps1", "verify.ps1", "write_notices.gd", "package.py", ".gdignore"]:
        archive.write(root / "tools" / name, "SpaceBetrayal/tools/" + name)
with zipfile.ZipFile(out / f"SpaceBetrayal-Source-{version}.zip") as archive:
    if archive.testzip() is not None:
        raise RuntimeError("Source archive failed CRC")
with zipfile.ZipFile(out / f"SpaceBetrayal-Android-{version}.apk") as apk:
    if apk.testzip() is not None:
        raise RuntimeError("APK failed CRC")
    members = apk.namelist()
    assert any("lib/arm64-v8a/libgodot_android.so" == n for n in members)
    assert "AndroidManifest.xml" in members
    assert any("GODOT_COPYRIGHT.txt" in n for n in members)
manifest = {"version": version, "date": "2026-10-18", "files": []}
for path in sorted(out.iterdir()):
    if path.name in {f"SpaceBetrayal-PC-{version}.zip", f"SpaceBetrayal-Source-{version}.zip", f"SpaceBetrayal-Android-{version}.apk"}:
        digest = hashlib.sha256(path.read_bytes()).hexdigest()
        manifest["files"].append({"name": path.name, "size": path.stat().st_size, "sha256": digest})
(out / f"manifest-{version}.json").write_text(json.dumps(manifest, indent=2), encoding="utf-8")
(out / "manifest.json").write_text(json.dumps(manifest, indent=2), encoding="utf-8")
print(json.dumps(manifest, indent=2))
