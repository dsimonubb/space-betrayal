"""Read selected, CRC-verified files from the official Godot template ZIP via HTTP ranges."""
import io
import pathlib
import struct
import urllib.request
import zipfile
import zlib

URL = "https://godot-releases.nbg1.your-objectstorage.com/4.7.2-stable/Godot_v4.7.2-stable_export_templates.tpz"
DEST = pathlib.Path(__file__).resolve().parent / "templates"

def fetch(start, size):
    req = urllib.request.Request(URL, headers={"Range": f"bytes={start}-{start + size - 1}"})
    with urllib.request.urlopen(req, timeout=120) as response:
        if response.status != 206:
            raise RuntimeError("Server ignored Range; refusing full archive download")
        data = response.read()
        if len(data) != size:
            raise RuntimeError("Incomplete download")
        return data

class RemoteZip(io.RawIOBase):
    def __init__(self):
        with urllib.request.urlopen(urllib.request.Request(URL, method="HEAD"), timeout=30) as response:
            self.length = int(response.headers["Content-Length"])
        self.pos = 0
    def seekable(self): return True
    def readable(self): return True
    def tell(self): return self.pos
    def seek(self, offset, whence=0):
        self.pos = offset if whence == 0 else self.pos + offset if whence == 1 else self.length + offset
        return self.pos
    def read(self, size=-1):
        size = min(self.length-self.pos, size if size >= 0 else self.length-self.pos)
        if size <= 0: return b""
        value = fetch(self.pos, size)
        self.pos += size
        return value

DEST.mkdir(exist_ok=True)
with zipfile.ZipFile(RemoteZip()) as archive:
    selected = [i for i in archive.infolist() if pathlib.PurePosixPath(i.filename).name in
                {"windows_release_x86_64.exe", "android_debug.apk", "android_release.apk", "version.txt"}]
    for info in selected:
        print(info.filename, info.file_size, "compressed", info.compress_size, flush=True)
        output = DEST / pathlib.PurePosixPath(info.filename).name
        if output.exists() and output.stat().st_size == info.file_size and zlib.crc32(output.read_bytes()) == info.CRC:
            print("Already verified", output.name, flush=True)
            continue
        header = fetch(info.header_offset, 30)
        name_len, extra_len = struct.unpack_from("<HH", header, 26)
        offset = info.header_offset + 30 + name_len + extra_len
        compressed = fetch(offset, info.compress_size)
        data = zlib.decompress(compressed, -15) if info.compress_type == zipfile.ZIP_DEFLATED else compressed
        if len(data) != info.file_size or zlib.crc32(data) != info.CRC:
            raise RuntimeError("CRC verification failed: " + info.filename)
        output.write_bytes(data)
        print("Verified", output, flush=True)
