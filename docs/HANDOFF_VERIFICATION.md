# Verificarea predării - 26 octombrie 2026

Verificările au fost executate în noul director AmongUs, nu doar în directoarele originale.

- Dependențele au fost restaurate din vendor/ după verificarea SHA-256, fără descărcări.
- Build-ul web a reușit. HTML-ul rezultat are 575.040 bytes și SHA-256 e670ea61f30247f9f09394ae2f84c7008196671877a2bb40a6227924fc7e556f, identic cu fișierul acceptat pentru Chinan.
- Cele 11 teste Node ale hărții, rolurilor și pachetului au trecut.
- Godot 4.7.2, sursa transferată: RULES 698 checks, 0 failures; HUNTER 32 checks, 0 failures; TOUCH UI 0 failures.
- Testul headless Hunter omite explicit capturarea click-ului, care necesită fereastră. Godot a raportat 5 instanțe ObjectDB neeliberate la ieșirea testului tactil; avertizarea nu este declarată rezolvată.
- Nu s-au recompilat exporturile Windows/Android istorice și nu s-a pretins o nouă testare pe telefon fizic sau verificare audio.
- Arhivele Windows/APK/sursă originale 0.2.0 sunt păstrate împreună cu manifestul lor. native/ este copia pentru dezvoltare, cu preset Android fără cheia/parolele originale și wrapper-e portabile.
- Fișierele proprii sunt inventariate în MANIFEST.sha256.json. Arhiva developer este verificată prin CRC și hash-ul fiecărui fișier.

Fișierele istorice README-original.md, logurile și utilitarele originale pot menționa căi sau unelte ale mașinii inițiale. Punctul de pornire actual este README.md din rădăcină și docs/BUILD_AND_TEST.md.
