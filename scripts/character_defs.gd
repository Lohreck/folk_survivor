class_name CharacterDefs
extends RefCounted
## Charakter-Definitionen (Charaktere-Dokument §1 Freischalt-Reihenfolge,
## §2 Archetypen; Gold-Kosten Wirtschaft §4).
##
## Reine Datenquelle für das Meta-Menü (Übersicht/Freischaltung) und – ab
## M3d – die Charakterauswahl. Gameplay-Felder (HP, Tempo, Startwaffe,
## Passiv) kommen mit der Auswahl (M3d); bis dahin dient die Tabelle der
## Übersicht, weil UI-UX §4 verlangt, gesperrte Charaktere sichtbar
## auszugrayen und die Freischalt-Bedingung als Text zu zeigen.

const CHARACTERS: Array[Dictionary] = [
	{"id": &"holzaeller", "name": "Der Holzfäller", "archetype": "Tank",
		"unlock_gold": 0, "hint": "Start-Charakter"},
	{"id": &"soldat", "name": "Der Verbannte Soldat", "archetype": "Balanced",
		"unlock_gold": 0, "hint": "Start-Charakter"},
	{"id": &"kraeuterfrau", "name": "Die Kräuterfrau", "archetype": "Glaskanone",
		"unlock_gold": 500, "hint": "500 Gold ODER 1× Rusalka besiegt"},
	{"id": &"waisenkind", "name": "Die Waisenkind-Figur", "archetype": "Mobil",
		"unlock_gold": 0, "hint": "Region 2 erreicht"},
	{"id": &"wanderpriesterin", "name": "Die Wanderpriesterin", "archetype": "Zonenkontrolle",
		"unlock_gold": 0, "hint": "Leshy besiegt"},
	{"id": &"jaeger", "name": "Der Jäger", "archetype": "Krit/Varianz",
		"unlock_gold": 1500, "hint": "Region 3 erreicht ODER 1500 Gold"},
	{"id": &"seelenhueter", "name": "Der Seelenhüter", "archetype": "Beschwörung",
		"unlock_gold": 0, "hint": "Region 4 erreicht"},
	{"id": &"zorya", "name": "Die Zorya-Priesterin", "archetype": "Licht/Anti-Nacht",
		"unlock_gold": 0, "hint": "Chernobog besiegt"},
]


static func get_def(id: StringName) -> Dictionary:
	for def: Dictionary in CHARACTERS:
		if def["id"] == id:
			return def
	return {}
