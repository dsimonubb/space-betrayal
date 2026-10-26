# SPACE BETRAYAL — OMEGA-9

Prototip jucabil, 0.2.0 — Hunter • 18 octombrie 2026

**Nou: Hunter este CREW**, apare cu Winchester echipată și poate elimina numai trădători. Alege `Hunter` în selectorul de rol înainte să intri în partidă. Pe PC țintești cu mouse-ul și tragi cu click stânga, Q sau F; pe Android folosești `Q · TRAGE`. Valori inițiale de prototip: 3 cartușe pe partidă, rază 25m, pauză 3s între focuri. Focurile ratate, contactele cu crew și scuturile consumă muniție. Crew nu moare din focurile Hunter, iar Hunter nu primește o pedeapsă pentru o țintă nevinovată. Pereții și primul corp din vizor opresc focul. Modelul armei și sunetul sunt originale și provizorii.

Actualizarea 0.1.1 activează compatibilitatea tactilă a controalelor standard din meniu, inclusiv selectorul numărului de participanți. Linkurile către imagini PNG afișează capturi statice; jocul Android se deschide prin aplicația instalată din APK.

## Pornește jocul

**Windows:** în arhiva `SpaceBetrayal-PC-0.2.0.zip`, extrage întregul director și deschide `SpaceBetrayal.exe`. Păstrează `SpaceBetrayal.pck` lângă executabil. Nu necesită instalarea Godot. Poți folosi și `PORNESTE-PC.cmd`, care păstrează datele și logurile local.

**Android:** transferă `SpaceBetrayal-Android-0.2.0.apk` pe un telefon Android cu procesor ARM64, deschide fișierul și instalează pachetul de test. Apoi deschide aplicația **Space Betrayal** din telefon. Acesta este semnat cu aceeași cheie de dezvoltare, package neschimbat și versionCode 3, astfel încât poate actualiza instalările anterioare. Nu este o versiune publicată în Google Play și nu a fost verificat pe un telefon fizic în această sesiune.

În meniu alegi 12–40 de participanți, 1–5 trădători și propriul rol. Restul participanților sunt **boți locali**, nu jucători conectați online. Pentru început: 12 participanți, 2 trădători, rolul Astronaut.

## Comenzi

| Acțiune | PC | Android |
| --- | --- | --- |
| Deplasare | W A S D | joystick în stânga |
| Privire | mouse | glisare în partea dreaptă, deasupra butoanelor |
| Terminal / masă de ședință | E | Folosește |
| Raportează o victimă | R | Raport |
| Abilitatea rolului | Q | Rol |
| Eliminare, doar trădător | F | Atac |
| Tragere Winchester, doar Hunter | click stânga / Q / F | TRAGE |
| Calibrare terminal | 1–4 sau clic | atinge modulele |
| Hartă | Tab | vizibilă implicit |
| Pauză / închide terminal | Esc | butonul Ⅱ / Deconectează |
| Sunet | M | opțiunea din pauză |

## Prima partidă

Explorează stația. Punctele aurii de pe hartă indică cele șase terminale. Apropie-te de unul, apasă E și repetă secvența de module afișată. Inginerul primește o secvență mai scurtă. Echipajul câștigă când toți membrii, inclusiv ecourile celor eliminați, termină misiunile sau când toți trădătorii sunt expulzați.

Raportează o victimă apropiată cu R sau convoacă o singură ședință de urgență lângă masa centrală cu E. Ședința durează cel mult 25s. Participanții eliminați nu votează. Egalitatea și majoritatea pentru abținere nu expulzează pe nimeni. Boții care au văzut un atac pot depune mărturie. Identitatea copiată de un Mimetic poate induce martorii în eroare.

Trădătorii câștigă la egalitate numerică cu echipajul rămas în viață sau dacă avaria reactorului nu este reparată în 75s. Ei pot sabota de la terminale. Sabotorul poate declanșa avaria și prin Q. Echipajul repară reactorul la oricare dintre cele două terminale din camera REACTOR. Rapoartele suspendă cronometrul avariei; avaria blochează convocarea de urgență de la masă.

## Cele 11 roluri în prototip

| Rol | Acțiune |
| --- | --- |
| Astronaut | Q indică cel mai apropiat terminal neterminat |
| Inginer | secvențe de calibrare mai scurte și localizare de misiuni |
| Medic | protecție 20s pentru participantul apropiat |
| Gardian | scut personal 15s |
| Detectiv | analiză lângă o victimă; în acest prototip dezvăluie atacatorul real |
| Hunter (crew) | Winchester echipată de la început; poate elimina numai trădători |
| Sabotor | declanșează avaria reactorului |
| Mimetic | copiază identitatea unui participant apropiat timp de 12s |
| Umbră | camuflaj 8s; atacul îl întrerupe |
| Asasin | deplasare accelerată 6s și pauză de eliminare redusă |
| Hacker | dezactivează harta de senzori timp de 20s |

Abilitățile sunt disponibile pentru jucătorul uman. În această etapă, boții se deplasează, fac misiuni, elimină, sabotează, repară, raportează și votează; nu folosesc încă toate abilitățile speciale. Boții Hunter apar cu arma și pot trage asupra unei identități pe care au văzut-o atacând, respectând muniția, pereții și imunitatea crew. Nu aleg ținte pe baza echipei secrete; o identitate copiată de Mimetic îi poate induce în eroare.

## Ce urmează

Obiectivul aprobat rămâne un joc 3D cu astronauți realiști și extratereștri înfricoșători, pe PC și Android. Modelele geometrice, animațiile simple și sunetele sintetice sunt resurse temporare. Transformarea extraterestră apare scurt la eliminare. Nu există încă modele realiste, chat între oameni sau servere online.

OMEGA-9 este singura hartă construită. LAVA-X, FROST-7, ABYSS și DARK MOON sunt planificate. Numărul de boți configurabil nu validează o sesiune online cu 40 de oameni. Echilibrarea, accesibilitatea, testele pe telefon și verificarea audio manuală rămân deschise.

## Dezvoltare

Deschide `project.godot` în [Godot 4.7.2](https://godotengine.org/download/windows/) și pornește scena principală cu F6 sau proiectul cu F5. Renderer: Compatibility / OpenGL. `scripts/match.gd` conține regulile, separat de scenă și UI. `catalog.gd` conține rolurile și datele misiunilor. `station.gd` construiește stația și rutele boților. `player.gd` gestionează inputul PC/tactil și coliziunile. `game.gd` orchestrează partida; `interface.gd` creează meniurile.

Exporturile sunt definite în `export_presets.cfg`. Căile custom de șabloane indică `tools/templates`; se pot schimba din editor sau se pot folosi șabloanele oficiale instalate. Utilitarul `tools/fetch_templates.py` descarcă selectiv șabloanele din arhiva oficială, verificând CRC. Pentru [export Android](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html), configurează OpenJDK și Android SDK în editor. Uneltele din această sesiune sunt locale, nu instalări globale. Nu include cheia de test în versiunea publicată.

Teste:

```powershell
godot --headless --path . --script res://tests/rules_test.gd
godot --headless --path . --script res://tests/touch_ui_test.gd
godot --headless --path . --script res://tests/hunter_test.gd
godot --headless --path . --fixed-fps 60 -- --integration
godot --headless --path . --fixed-fps 60 -- --bot-simulation
godot --headless --path . --fixed-fps 60 -- --bot-simulation-40
```

Simulările completează automat misiunile jucătorului după 60s și aleg abținerea la vot pentru el. Sunt teste de progres al partidei, nu dovezi de echilibrare naturală sau de performanță GPU.

Vezi `Docs/STATUS.md` pentru dovezi și limite. Runtime-ul Godot și bibliotecile sale sunt descrise în `THIRD_PARTY_NOTICES.md`.
