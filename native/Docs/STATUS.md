# Prototip 0.1 — stadiu și verificare

18 octombrie 2026. Proiect separat de In the Dojo.

## Actualizare 0.2.0 — Hunter

Utilizatorul a cerut un rol nou, Hunter, cu Winchester la spawn și a confirmat explicit că este crew și poate elimina doar trădători. Numărul de roluri devine 11. Hunter păstrează misiunile, raportarea și votul echipajului. Nu poate sabota.

Arma este un model geometric original de prototip, vizibil în prima persoană și la boți. Are animație de foc/mecanism și sunet sintetic original. Valori alese pentru primul test: 3 cartușe, 25m, pauză 3s. Aceste valori nu sunt cerințe de balans ale utilizatorului. Focurile în crew, scut și ratările consumă muniție fără eliminare. Nu există pedeapsă automată pentru Hunter dacă țintește un nevinovat, în acord cu varianta aleasă de utilizator.

Selecția țintei folosește raza din centrul camerei și primul corp din traiectorie, fără filtrare după echipa secretă. Pereții blochează focul. Boții Hunter au arma și pot reacționa la propriile mărturii, folosind aceeași trasare; nu selectează trădătorii prin cunoașterea ascunsă a rolurilor.

`tests/hunter_test.gd` verifică apartenența crew, spawn cu muniție/armă, misiuni, blocarea sabotajului, ținte crew nevătămate, consum de muniție, ciclul între focuri, rază, scut, moarte, ședințe, victorie prin ultimul trădător, corp raportabil, vizor, pereți și butonul de tragere cu al doilea deget. Testele sunt automate prin motor, nu execuție pe telefon fizic. Capturi: `artifacts/hunter.png` și `artifacts/hunter-touch.png`.

Rezultatul Hunter: **33 verificări, 0 eșecuri** cu fereastră OpenGL, inclusiv click capturat și tasta F injectate prin Input. Varianta headless execută 32 verificări și omite explicit capturarea mouse-ului, care nu este disponibilă fără fereastră. S-au verificat și testele tactile, cele 698 verificări ale regulilor, integrarea pachetului Windows, cele două simulări de progres, cele șase capturi ale pachetului și semnătura APK. Acestea nu certifică tastatura fizică, ascultarea audio sau telefonul real.

Matricea regulilor existente este extinsă la 11 roluri: 698 verificări. Fluxul de integrare acoperă acum 11 acțiuni de rol. APK-ul nou păstrează cheia/pachetul și crește versionCode la 3. Pachetele mai vechi se păstrează separat.

## Actualizare 0.1.1 — meniuri tactile

Utilizatorul a clarificat că deschidea captura în browser, nu aplicația instalată. Capturile PNG sunt statice. Separat, verificarea a identificat un defect real: selectorul SpinBox al numărului de participanți nu creștea la atingere cu emularea pointerului dezactivată. Testul `artifacts/touch-ui-baseline.log` reproduce acest defect; butonul Start răspundea deja în această verificare, deci nu pretindem reproducerea unui blocaj total al meniului.

`input_devices/pointing/emulate_mouse_from_touch` este acum true. Evenimentele tactile native continuă să controleze mișcarea și privirea; controalele standard primesc și pointerul compatibil. Testul automat prin `Input.parse_input_event` verifică selectorul, comutatorul fără activare dublă, Start, abilitatea Q cu al doilea deget în timp ce primul ține joystickul, pauza și reluarea. Testul trece, la fel și integrarea existentă. Aceasta este simulare tactilă prin motor, nu validare pe telefon fizic.

APK 0.1.1 folosește versionCode 2 și aceeași identitate de pachet/cheie ca 0.1, pentru actualizare directă. Pachetele și sursa 0.1 originale se păstrează în `deliverables/`.

## Livrat

- Proiect Godot 4.7.2, scenă 3D originală OMEGA-9, perspectivă la persoana întâi, deplasare cu coliziuni și privire liberă.
- Windows x64: executabil nativ și PCK, fără a necesita editorul instalat.
- Android: APK ARM64 semnat cu cheie de dezvoltare. Manifest verificat: min SDK 24 (Android 7), target SDK 36, package `org.spacebetrayal.omega9`. Compatibilitatea efectivă a dispozitivelor rămâne de testat.
- Configurare 12–40 participanți și 1–5 trădători, un om și restul boți locali. Fără servere sau conexiuni online.
- Șase terminale cu calibrare interactivă, progres personal și comun, sabotaj și repararea reactorului, victime, raportare, ședințe, vot, abținere, egalitate, expulzare și rezultate.
- Unsprezece roluri cu acțiuni distincte pentru om, inclusiv Hunter crew; abilități cu pauze și durate. Boții au un subset de comportamente; vezi README.
- Intrare PC și tactilă, hartă, pauză, revenire în meniu, sunete originale sintetice de pași, alarme și terminale.
- Costume umane și transformare extraterestră scurtă la eliminare. Modelele și animațiile sunt geometrie temporară, fără acceptare ca artă realistă finală.
- Licențe Godot accesibile și din meniul jocului.

## Dovezi automate

`tools/verify.ps1 -Rendered` verifică sursa, pachetul Windows, randarea și semnătura APK. Loguri și capturi în `artifacts/`.

| Verificare | Rezultat și limită |
| --- | --- |
| `rules_test.gd` | 698 verificări, 0 eșecuri: combinații 12/24/40 participanți × 1–5 trădători × 11 roluri, ID-uri invalide, misiuni duplicate, limite de atac, scut, victime, raportare, vot unic, morți fără vot, abținere, egalitate, expulzare, avarie, reparație, victorii prin misiuni și paritate. |
| Integrare scenă | Terminal real și puzzle, oprirea timpului la pauză, input tactil, deplasare în perete cu coliziune, ședință, abținere, revenire, victorie prin misiuni, ecran rezultat, intrarea în acțiunea fiecăruia dintre cele 11 roluri. |
| Integrare executabil Windows | Aceeași secvență a trecut în pachetul nativ, încărcând scenele și scripturile exportate. |
| Simulare cu 12 participanți, 2 trădători, seed 742, versiunea 0.2 | Echipajul câștigă prin descoperirea tuturor trădătorilor după aproximativ 62,52s active / 69,15s inclusiv ședințe. |
| Simulare cu 40 participanți, 5 trădători, seed 742 | Echipajul câștigă prin descoperirea tuturor trădătorilor după aproximativ 67,93s active / 101,03s inclusiv ședințe. Nu dovedește echilibrare. |
| Randare Windows | Meniu, perspectivă PC, HUD tactil și ședință randate în OpenGL pe Intel Graphics. PNG-urile pot fi inspectate. |
| APK | Export reușit, integritate ZIP și manifest verificate; semnături APK v2/v3 confirmate cu apksigner. |

În simulări, automatizarea completează toate misiunile omului după 60s și îl face să se abțină. Nu înlocuiește testarea umană. Rulează cu timp fix accelerat; timpii de simulare NU sunt măsurători FPS/GPU. Un singur seed nu validează echilibrarea botului.

## Particularități de mediu

- Un cache OpenGL generat a provocat eșecuri de încărcare a shaderelor și un crash în driverul Intel `igxelpicd64.dll`. Cache-ul shaderelor pe disc este dezactivat în acest prototip; pornirile grafice repetate ulterioare au reușit. Nu s-au modificat driverul sau politicile Windows.
- Godot raportează imposibilitatea citirii magazinului de certificate OS în mediul restricționat și folosește certificatele sale incluse. Jocul local nu utilizează conexiuni de rețea.
- Unele închideri foarte rapide în teste headless raportează instanțe audio neeliberate la ieșire. Testele și exporturile trec, dar această avertizare nu este ascunsă sau declarată rezolvată.
- Exportul Android folosește uneltele 35.0.1 pentru semnarea/alinierea unui șablon target SDK 36, cu avertizare de versiune. APK-ul rezultat trece verificarea semnăturii și structurii. Instrumentele sunt locale în `tools/`.

## Acceptare deschisă

1. Instalare și joc pe un telefon Android fizic: atingere simultană, navigare, aspect, sunet, temperatură, performanță și reluare după suspendare.
2. Tastatură și mouse fizice, ascultare audio și partide umane complete pe PC; testele automate nu certifică senzația comenzilor.
3. Modele, texturi, animații și decor cu realismul ales de utilizator. Grafică actuală de prototip, nu finală.
4. Arhitectură de server autoritar și sesiuni online PC–Android de 12–40 de oameni, lobby, reconnect, validare, moderare și interfață de discuții.
5. Celelalte patru hărți. Doar OMEGA-9 este construită; celelalte nume sunt în catalogul de planificare.
6. Echilibrare pe mai multe seed-uri și durate, comportamente complete pentru rolurile boților, investigație mai puțin directă și prezentare vizuală aprofundată a abilităților.

Arhivele PC, APK și sursa sunt în `deliverables/`. `manifest.json` păstrează dimensiunile și SHA-256 ale pachetelor livrate.
