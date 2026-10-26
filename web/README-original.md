# Space Betrayal — ediție web pentru școală

Actualizare OMEGA-9 ×6: 318 dale de 4×4m (5.088m² de podea nominală), față de 53 dale (848m²) în prima ediție. Suprafața este exact de șase ori mai mare; dimensiunile personajelor și viteza de mers rămân aceleași. Patru sectoare noi — Laborator, Navigație, Seră orbitală și Hangar — sunt legate de o galerie perimetrală cu scurtături. Observator în extremitatea nordică. Terminalele sunt distribuite în noile sectoare; minimapa se încadrează automat în limitele stației.

Joc 3D la persoana întâi, cu identități secrete, misiuni și ședințe de vot. Un om și 11–39 boți locali; 1–5 trădători; 11 roluri. Hartă: OMEGA-9. Fără multiplayer online. Hunter aparține echipajului și folosește un scanner de neutralizare cu trei încărcări, rază 25m și pauză 3s. Scannerul nu izolează echipajul și nu traversează pereți sau costume aflate în față.

Versiunea nativă Godot este păstrată separat. Această ediție folosește geometrie și audio procedural, fără arme realiste, răniri sau scene de moarte.

## Joc și instalare

Deschide dist/index.html direct într-un browser modern cu WebGL2. Pentru host static, copiază index.html într-un director precum public_html/jocuri/space-betrayal/. Adresa va fi calea acelui director. Nu necesită Node, PHP, bază de date sau chei API pe host. Toate resursele sunt incluse în HTML; funcționează în subdirectoare.

Pachetul de predare conține index.html, citeste-ma.txt și fisa-jocului.txt. Fișa trebuie completată cu autorul și clasa înainte de predarea către școală. Domeniul cerut de utilizator este chiran.ro; documentul furnizat folosește chinan.ro. Nu am modificat domenii sau conturi de hosting.

## Comenzi

PC: WASD sau săgeți pentru deplasare; mouse capturat sau glisare pe scenă pentru privire; E terminal/ședință; R raport; Q abilitatea rolului; F izolare/scanare; click stânga cu Hunter când mouse-ul este capturat; Esc pauză; Tab hartă; M sunet. La terminal: butoanele numerice sau tastele 1–4. Telefon: joystick stânga, glisare pentru privire, butoane tactile dreapta; suport pentru două degete simultan.

Echipajul câștigă prin terminarea tuturor misiunilor sau izolarea tuturor trădătorilor. Trădătorii câștigă la paritate numerică sau expirarea avariei de 75s. După izolare, un membru al echipajului poate continua misiunile ca ecou holografic, fără vot sau abilități. Rezultatul permite reluarea sau revenirea în meniu.

## Dezvoltare și verificare

Node și pnpm, versiuni fixate în package.json și pnpm-lock.yaml. pnpm install, apoi node scripts/build.mjs. Biblioteca Three.js este inclusă în fișierul rezultat, iar licența MIT este accesibilă în ajutorul jocului. node --test tests/rules.test.mjs tests/package.test.mjs verifică regulile și pachetul.

Testele browser.cjs și mechanics.cjs sunt instrumente locale de verificare, cu Playwright și Edge din mediul de lucru; căile lor trebuie adaptate pe alt PC. Pentru ele: node scripts/build.mjs --test și server static la rădăcina proiectului, port 18780. Numai pagina de test din evidence/test expune instrumentarea; dist/index.html nu o conține. Rezultatele și limitele sunt consemnate în evidence/verification.md.

Ediția necesită JavaScript și WebGL2. Browserele vechi sau dispozitivele cu WebGL dezactivat afișează explicația de compatibilitate. Nu există colectare de date, conturi, scoruri trimise pe server sau salvare persistentă.
