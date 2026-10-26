# Build și verificare

## Web

Pentru reproducere pe Windows x64 fără rețea:

    python scripts/restore-vendor.py
    cd web
    node scripts/build.mjs
    node --test tests/rules.test.mjs tests/package.test.mjs

Build-ul scrie un singur web/dist/index.html și păstrează documentele din dist/. Copia acceptată pentru Chinan rămâne în releases/chinan-2026-10-24/, independent de build-urile noi.

Pentru Linux/macOS sau instalare din registru: Node 18+, pnpm 11.25.0, pnpm install --frozen-lockfile din web/. Pachetul esbuild nativ este specific platformei, iar copia vendor inclusă este Windows x64.

### Teste browser opționale

Instalează Playwright în mediul de dezvoltare (de exemplu npm install --no-save playwright din web/) și browserul pentru el (npx playwright install chromium). Poți seta BROWSER_EXE către un Chrome/Edge instalat și PLAYWRIGHT_MODULE către modulul Playwright, dacă nu este în node_modules normal.

Din web/:

    node scripts/build.mjs --test
    python -m http.server 18780 --bind 127.0.0.1

În alt terminal, tot din web/:

    node tests/browser.cjs
    node tests/mechanics.cjs
    node tests/expanded-map.cjs

Pagina instrumentată se generează doar în web/evidence/test/. HTML-ul de producție nu expune obiectul de test. Testele salvează rezultatele în web/evidence/; evidence/web/ de la rădăcină este snapshot-ul istoric.

## Godot

Instalează Godot 4.7.2. Poți rula direct:

    godot --headless --path native --script res://tests/rules_test.gd
    godot --headless --path native --script res://tests/hunter_test.gd
    godot --headless --path native --script res://tests/touch_ui_test.gd

Sau folosește scripts/test-native.ps1 -GodotExe <cale-godot>.

Pentru export Windows/Android sunt necesare șabloanele oficiale 4.7.2. Configurează Godot pentru JDK 17 și Android SDK/build-tools înaintea exportului Android; în sesiunea originală s-au folosit build-tools 35.0.1 și template target SDK 36. Utilitarele originale native/tools/build.ps1 și verify.ps1 sunt păstrate ca referință și presupun unelte locale în native/tools/. Wrapperul nou scripts/build-native.ps1 acceptă motorul instalat separat.

Presetul Android este fără cheia și parolele originale. Configurează un debug/release keystore propriu prin editor. Cheia istorică nu este necesară pentru deschiderea sursei sau pentru build Windows.

## Arhiva developer

    python scripts/package-handoff.py

Se regenerează inventarul SHA-256 și arhiva distribution/space-betrayal-developer-2026-10-26.zip, fără .git, cache-uri, node_modules, unelte externe sau chei. Arhiva conține și pachetele vendor, build-urile native actuale și snapshot-urile de verificare.
