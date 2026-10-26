# Space Betrayal - developer handoff

Predare completă a jocului, 26 octombrie 2026. Autor proiect: Sebastian, clasa 3D.

**Versiunea actuală acceptată este web OMEGA-9 x6**, în web/. Jocul public este la https://space-betrayal-omega-nine.sebastiansb16ro.chatgpt.site. Codul jocului și CSS-ul au fost comparate cu versiunea publicată. Prototipul Godot PC/Android 0.2.0 este păstrat separat în native/; harta lui nu a fost extinsă x6 și Hunter folosește Winchester, în timp ce ediția școlară web folosește scanner.

## Structură

- web/: toate sursele JS, HTML, CSS, build-ul index.html, testele și lockfile-ul.
- native/: proiectul Godot complet, scene, icon, toate scripturile, testele și utilitarele de export.
- releases/chinan-2026-10-24/: pachetul predat pentru site-ul școlii, fișa și licențele.
- releases/native-0.2.0/: exportul Windows, APK-ul ARM64 și manifestul original.
- vendor/: copii ale dependențelor web folosite, cu sursele lor și licențele; permite build offline pe Windows x64 după instalarea Node/Python.
- evidence/: loguri, capturi și rezultatele testelor istorice.
- docs/: starea actuală, inventarul asseturilor, verificări și ghidul de găzduire.
- scripts/: restaurare dependențe, teste și împachetarea predării.
- MANIFEST.sha256.json: inventarul fișierelor, dimensiuni și SHA-256.

## Pornește versiunea web

Deschide web/dist/index.html sau releases/chinan-2026-10-24/index.html cu dublu-click. Nu sunt necesare server, cont OpenAI, backend sau resurse externe. Browser modern cu JavaScript și WebGL2.

## Build web offline - Windows x64

Ai nevoie de Node.js 18+ și Python 3.12+. Din rădăcina repository-ului:

    python scripts/restore-vendor.py
    cd web
    node scripts/build.mjs
    node --test tests/rules.test.mjs tests/package.test.mjs

Copiile vendor sunt exact three 0.180.0, esbuild 0.25.10 și binarul esbuild Windows x64 corespunzător. Pentru alte sisteme sau instalare normală, din web/ folosește pnpm 11.25.0 install --frozen-lockfile și pnpm build. Lockfile-ul original este inclus; nu este nevoie să schimbi dependențele pentru a rula HTML-ul livrat.

Testele de browser sunt opționale și necesită Playwright instalat în mediul developerului. Vezi docs/BUILD_AND_TEST.md.

## Godot PC/Android

Deschide native/project.godot cu Godot 4.7.2, renderer Compatibility. Toate asseturile jocului sunt incluse sau generate din cod; nu există un pachet extern de modele care lipsește. Pentru a juca exporturile existente, extrage integral ZIP-ul Windows sau instalează APK-ul din releases/native-0.2.0/.

Editorul Godot, SDK/JDK și șabloanele de export sunt unelte externe de dezvoltare. Versiunile, sursele de descărcare și hash-urile exemplarelor originale sunt documentate în docs/. Nu sunt asseturi ale jocului și nu sunt duplicate în repository. Pentru export, folosește șabloanele oficiale 4.7.2; scriptul native/tools/fetch_templates.py le poate descărca selectiv.

Cheia Android de dezvoltare nu este inclusă. Preseturile transferate nu conțin parole sau cheia originală. Configurează propria cheie în Godot înainte de un nou export Android; o semnătură diferită poate necesita dezinstalarea vechiului APK de test.

## Stare și limite

Un om și boți locali, 12-40 participanți, 1-5 trădători, 11 roluri; nu există multiplayer online. Web are o singură hartă OMEGA-9 extinsă, șase terminale, galerie perimetrală și patru sectoare noi. Vezi docs/CURRENT_STATE.md pentru verificări și limite reale.

Nu a fost atribuită o licență open-source codului original al jocului. Licențele third-party sunt în licenses/ și în native/; nu trebuie confundate cu o licență pentru întregul proiect.
