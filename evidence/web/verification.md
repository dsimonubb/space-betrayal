# Verificare — 22 octombrie 2026

Actualizare OMEGA-9 ×6:
- 11 teste Node trecute, inclusiv raportul exact 318/53 = 6, conectivitatea tuturor dalelor libere și trasee între sectoare cu nodul central indisponibil.
- 54 trasee de la nodul central, patru sectoare noi, Observator și punctele galeriei la cele șase terminale: eșantionare la maximum 15cm, fără traversarea obstacolelor scenei. Minimapă încadrată din limitele actuale ale hărții.
- Au trecut din nou cele trei fluxuri UI în Edge (desktop, portret și peisaj), pornirea file://, multi-touch, raycast și cele 12 simulări accelerate după extindere și schimbarea rutelor.
- Capturi inspectate: Laborator, Seră orbitală, Observator; s-au generat și capturi pentru Navigație și Hangar. Suprafață nominală de podea: 5.088m² față de 848m². Valoarea include podeaua de sub recuzită, la fel în ambele variante; nu este un test de performanță GPU.
- Limitele de verificare de mai jos rămân valabile, inclusiv lipsa testării pe Android fizic. Date noi în expanded-map-results.json și expanded-*.png.

Verificarea inițială a ediției web:

- 9 teste Node trecute: matricea a 1.595 combinații de număr de participanți/trădători/roluri; scanner, imunitate echipaj, încărcări, cooldown, scut, distanță; misiuni, deduplicare, ecouri, reactor, ședințe și voturi, izolare și trasee.
- Edge headless pe Windows, WebGL2: desktop 1440×900, telefon emulat 390×844, peisaj 844×390. Pornire, deplasare prin taste/atingere, pauză cu timpul oprit, terminal calibrat prin butoane, abținere la vot, victorie, înfrângere, reluare și revenire în meniu.
- Nicio eroare JavaScript în aceste fluxuri. Câte o cerere pentru HTML, fără cereri externe de resurse ale jocului. Fișierul de producție pornește și prin file:// și nu expune instrumentarea de test.
- Test cu două puncte tactile simultane: deplasare și rotirea privirii. Test de raycast în scena 3D: țintă liberă, costum în față și perete.
- 12 simulări accelerate folosind regulile și deplasarea boților, cu 12/40 participanți și 1–5 trădători, toate încheiate prin condiții valide. Misiunile omului au fost completate programatic; voturile omului au fost abțineri. Aceste verificări demonstrează continuitatea simulării, nu echilibru de dificultate sau performanță reală.
- Capturi inspectate vizual pentru meniu și joc pe desktop, portret și peisaj. Scannerul a fost adaptat suplimentar pentru ecrane înguste.

Limite: nu s-a testat pe telefon Android fizic, în Safari/Firefox sau pe toate GPU-urile. Sunetele sunt generate prin Web Audio și se activează prin gestul de pornire; nu s-a făcut o evaluare auditivă fizică. Nu se afirmă compatibilitate cu orice browser vechi sau performanță stabilă pe toate dispozitivele. Verificările rezultatelor în UI folosesc stări de test injectate; nu constituie un meci jucat integral de o persoană pe telefon.

Fișiere brute: browser-results.json, mechanics-results.json și capturile PNG din acest director. evidence/ nu se publică pe Sites și nu intră în pachetul școlii.
