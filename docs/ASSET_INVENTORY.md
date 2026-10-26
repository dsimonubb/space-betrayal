# Inventarul asseturilor și resurselor

Jocul nu folosește un set extern de personaje sau texturi lipsă. Stația, costumele, scannerul, arma prototipului și sunetele sunt generate procedural din sursele incluse.

| Resursă | Web | Godot |
| --- | --- | --- |
| Geometrie stație, terminale, decor | web/src/scene.mjs | native/scripts/station.gd |
| Hartă, trasee, misiuni, roluri | web/src/rules.mjs | native/scripts/catalog.gd, station.gd, match.gd |
| Costume, holograme, echipamente | web/src/scene.mjs | native/scripts/astronaut.gd, hunter.gd, winchester.gd |
| Sunete originale sintetice | clasa Audio din web/src/app.mjs | native/scripts/sound.gd |
| UI, text, CSS, input | web/src/app.mjs, template.html, style.css | native/scripts/interface.gd, player.gd, game.gd |
| Icon original | favicon SVG inline | native/icon.svg |
| Motor grafic și licențe | vendor/three-0.180.0.tgz, licenses/three | GODOT_COPYRIGHT.txt, THIRD_PARTY_NOTICES.md |
| Build/teste | web/scripts, web/tests | native/tools, native/tests |
| Build-uri de distribuit | web/dist, releases/chinan-2026-10-24 | releases/native-0.2.0 |
| Capturi și dovezi | evidence/web | evidence/native |

Pachetele vendor conțin și fișierele upstream livrate cu dependențele; acestea nu înseamnă că exemplele sau asseturile demonstrative ale bibliotecilor sunt folosite în joc.

Sunt omise cache-urile .godot, node_modules duplicate, SDK/JDK/editor, fișiere temporare, exporturi vechi 0.1/0.1.1, istoricul Git Sites și cheile de semnare. Sunt incluse toate sursele și asseturile proprii ale versiunilor actuale, exporturile 0.2.0, resursele web folosite și informațiile de reconstruire a uneltelor. Hash-urile uneltelor originale sunt în external-tooling.json.
