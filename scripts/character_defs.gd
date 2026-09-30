class_name CharacterDefs
extends RefCounted
## Charakter-Definitionen (Charaktere-Dokument §1 Freischalt-Reihenfolge,
## §2 Archetypen; Gold-Kosten Wirtschaft §4).
##
## EINE Datenquelle für Meta-Menü (Übersicht/Freischaltung/Auswahl) und den
## Run-Start (main.gd liest HP/Tempo/Startwaffe/Passiv beim Spawn).
##
## `playable` = Kit ist technisch umgesetzt. Ab M3 sind das Holzfäller,
## Soldat und Kräuterfrau (M3d-Scope: „mindestens 1 weiterer Charakter“);
## die restlichen bleiben mit ihrer Freischalt-Bedingung als Vorschau
## sichtbar (UI-UX §4: gesperrte Charaktere ausgrauen, Bedingung zeigen).
## „Alle 8 Charaktere final“ ist M4.

const CHARACTERS: Array[Dictionary] = [
	{"id": &"holzaeller", "name": "Der Holzfäller", "archetype": "Tank",
		"unlock_gold": 0, "hint": "Start-Charakter", "playable": true,
		"max_hp": 140.0, "speed_mult": 0.8,
		"start_weapon": &"axe_holzfaenger", "weapon_label": "Axt",
		"passive": &"zaehe_haut"},
	{"id": &"soldat", "name": "Der Verbannte Soldat", "archetype": "Balanced",
		"unlock_gold": 0, "hint": "Start-Charakter", "playable": true,
		"max_hp": 100.0, "speed_mult": 1.0,
		"start_weapon": &"sichel", "weapon_label": "Sichel",
		"passive": &"kampferfahrung"},
	{"id": &"kraeuterfrau", "name": "Die Kräuterfrau", "archetype": "Glaskanone",
		"unlock_gold": 500, "hint": "500 Gold ODER 1× Rusalka besiegt", "playable": true,
		"max_hp": 70.0, "speed_mult": 1.0,
		"start_weapon": &"weihwasser_phiole", "weapon_label": "Weihwasser-Phiole",
		"passive": &"segende_hand"},
	{"id": &"waisenkind", "name": "Die Waisenkind-Figur", "archetype": "Mobil",
		"unlock_gold": 0, "hint": "Region 2 erreicht", "playable": false},
	{"id": &"wanderpriesterin", "name": "Die Wanderpriesterin", "archetype": "Zonenkontrolle",
		"unlock_gold": 0, "hint": "Leshy besiegt", "playable": false},
	{"id": &"jaeger", "name": "Der Jäger", "archetype": "Krit/Varianz",
		"unlock_gold": 1500, "hint": "Region 3 erreicht ODER 1500 Gold", "playable": false},
	{"id": &"seelenhueter", "name": "Der Seelenhüter", "archetype": "Beschwörung",
		"unlock_gold": 0, "hint": "Region 4 erreicht", "playable": false},
	{"id": &"zorya", "name": "Die Zorya-Priesterin", "archetype": "Licht/Anti-Nacht",
		"unlock_gold": 0, "hint": "Chernobog besiegt", "playable": false},
]


static func get_def(id: StringName) -> Dictionary:
	for def: Dictionary in CHARACTERS:
		if def["id"] == id:
			return def
	return {}


## Kurz-Statzeile für Auswahlkarten (nur spielbare Kits haben Gameplay-Felder).
static func stats_line(id: StringName) -> String:
	var def := get_def(id)
	if def.is_empty() or not bool(def.get("playable", false)):
		return ""
	return "%d HP · %s× Tempo · %s" % [
		int(float(def.get("max_hp", 0.0))),
		str(_fmt_mult(float(def.get("speed_mult", 1.0)))),
		str(def.get("weapon_label", "")),
	]


static func _fmt_mult(value: float) -> String:
	# 0.8 → „0.8“, 1.0 → „1.0“ (eine Nachkommastelle, Punkt wie im GDD).
	return "%.1f" % value
