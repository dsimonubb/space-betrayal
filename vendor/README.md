# Dependențe de build incluse

Arhivele sunt copii ale pachetelor folosite în build-ul original, făcute din instalarea locală și păstrând sursa și licențele. Nu sunt instalatoare de SDK, nu conțin tokenuri. Verifică SHA-256 în manifest.json înainte de restaurare.

- three 0.180.0, JavaScript.
- esbuild 0.25.10, wrapper și surse JS distribuite upstream.
- @esbuild/win32-x64 0.25.10, compilatorul nativ Windows x64.

scripts/restore-vendor.py le extrage în web/node_modules după verificarea hash-urilor. Pe altă platformă, folosește lockfile-ul și pachetul esbuild oficial al acelei platforme.
