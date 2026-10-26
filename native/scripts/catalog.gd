extends RefCounted

const CREW_ROLES = ["Astronaut", "Inginer", "Medic", "Gardian", "Detectiv", "Hunter"]
const TRAITOR_ROLES = ["Sabotor", "Mimetic", "Umbră", "Asasin", "Hacker"]
const ROLE_INFO = {
	"Astronaut": "Q: localizezi următoarea misiune. Repară stația și descoperă trădătorii.",
	"Inginer": "Q: localizezi misiuni. Calibrezi terminalele de două ori mai repede.",
	"Medic": "Q: protejezi astronautul apropiat timp de 20 secunde. Pauză: 35s.",
	"Gardian": "Q: scut personal timp de 15 secunde. Pauză: 35s.",
	"Detectiv": "Q lângă o victimă: analizezi urmele lăsate de atacator.",
	"Hunter": "Echipaj · Winchester de la început. Click / Q / F: tragi. 3 cartușe. Poți elimina doar trădători.",
	"Sabotor": "Q: declanșezi avaria reactorului. Echipajul are 75s să intervină.",
	"Mimetic": "Q: copiezi identitatea unui astronaut apropiat pentru 12s.",
	"Umbră": "Q: devii invizibil pentru 8s. Atacul încheie camuflajul.",
	"Asasin": "Q: accelerație timp de 6s. Eliminări cu pauză de 22s.",
	"Hacker": "Q: oprești harta de senzori pentru 20s. Pauză: 40s."
}
const MAPS = ["OMEGA-9", "LAVA-X", "FROST-7", "ABYSS", "DARK MOON"]
const NAMES = ["TU", "NOVA", "ATLAS", "IRIS", "ORION", "VEGA", "KAI", "LYRA", "AXEL", "LUNA", "ECHO", "SOL", "ASTRA", "NEON", "RHEA", "TITAN", "IO", "ARES", "ELARA", "NYX", "ZEN", "ARCO", "HALO", "MIRA", "ZENIT", "ARGO", "QUASAR", "LEO", "DIONE", "ERIS", "SIRIUS", "ALTAIR", "RIGEL", "CAPELLA", "SORA", "THEA", "CATO", "NIX", "ARIEL", "CAL"]
const COLORS = [Color("65e5db"), Color("ef9555"), Color("598fd8"), Color("c87fbb"), Color("e7d26b"), Color("98c6b2"), Color("b4baca"), Color("ca625d"), Color("8181c1"), Color("d8af91"), Color("75b375"), Color("72b8cf")]
const TASKS = [
	{"id": 0, "name": "REACTOR · calibrare", "pos": Vector3(2.8, 0, -21.5), "room": "REACTOR"},
	{"id": 1, "name": "COMUNICAȚII · antenă", "pos": Vector3(21.5, 0, 2.8), "room": "COMUNICAȚII"},
	{"id": 2, "name": "INFIRMERIE · bioscaner", "pos": Vector3(-21.5, 0, -2.8), "room": "INFIRMERIE"},
	{"id": 3, "name": "SUPORT VITAL · filtre", "pos": Vector3(-2.8, 0, 21.5), "room": "SUPORT VITAL"},
	{"id": 4, "name": "REACTOR · energie", "pos": Vector3(-2.8, 0, -18), "room": "REACTOR"},
	{"id": 5, "name": "COMUNICAȚII · date", "pos": Vector3(18, 0, -2.8), "room": "COMUNICAȚII"}
]

static func is_traitor(role: String) -> bool:
	return role in TRAITOR_ROLES

static func color_for(id: int) -> Color:
	return COLORS[id % COLORS.size()]
