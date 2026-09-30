extends Node
## MetaProgress-Autoload (Technisches Konzept §6, Technisches Setup §6).
##
## Hält den persistenten Meta-Spielstand: Gold, Bernstein, Talentbaum,
## Charakter-/Regionen-Freischaltungen und besiegte Bosse. Speichert als
## versioniertes JSON nach `user://save_data.json` (Schema: Technisches
## Setup §6 „save_data.gd"); jede Mutation schreibt sofort (autosave),
## damit Abstürze keinen Fortschritt kosten.
##
## Werte-Quellen: Wirtschaft §2 (Gold-Einnahmen), §3 (Talentbaum-Kosten-
## kurve Basis × 1.35^(n-1)), Playtesting §5.3 (Gold-Rate Soft-Cap +50 %),
## Charakterliste (Freischalt-Bedingungen, Charaktere-Dokument §1).

signal gold_changed(total: int)

const SAVE_PATH := "user://save_data.json"
const SAVE_VERSION := 1

## Talent-Knoten. Kosten(Stufe n) = base_cost × 1.35^(n-1) (Wirtschaft §3).
## Der Effekt pro Stufe steckt in den run-seitigen *_bonus/-multiplikator-
## Helfern unten, damit die UI nur Namen/Beschreibung/Kosten braucht.
const TALENT_DEFS := {
	&"start_hp": {
		"name": "Ahnensegen",
		"description": "+5 Start-HP pro Stufe",
		"base_cost": 50,
		"max_level": 10,
	},
	&"gold_rate": {
		"name": "Glückshändler",
		"description": "+5 % Gold pro Stufe (Stufe 10 = +50 % Soft-Cap)",
		"base_cost": 80,
		"max_level": 10,
	},
	&"rerolls": {
		"name": "Wahrsagerei",
		"description": "+1 Karten-Reroll pro Run",
		"base_cost": 100,
		"max_level": 2,
	},
}

## Beide Start-Charaktere sind von Anfang an frei (Charaktere-Dokument §1).
const DEFAULT_CHARACTERS: Array[StringName] = [&"holzaeller", &"soldat"]
const DEFAULT_REGIONS: Array[int] = [1]

var gold := 0
var bernstein := 0
## Talent-Levels: StringName -> int (nur bekannte Knoten aus TALENT_DEFS).
var talents := {}
var unlocked_characters: Array[StringName] = []
var unlocked_regions: Array[int] = []
var bosses_defeated: Array[StringName] = []


func _ready() -> void:
	load_game()


# ---------------------------------------------------------------------------
# Gold
# ---------------------------------------------------------------------------

func add_gold(amount: int) -> void:
	if amount == 0:
		return
	gold = maxi(0, gold + amount)
	_save()
	gold_changed.emit(gold)


func spend_gold(amount: int) -> bool:
	if amount < 0 or gold < amount:
		return false
	gold -= amount
	_save()
	gold_changed.emit(gold)
	return true


# ---------------------------------------------------------------------------
# Talentbaum (Wirtschaft §3)
# ---------------------------------------------------------------------------

func talent_ids() -> Array:
	return TALENT_DEFS.keys()


func talent_level(id: StringName) -> int:
	return int(talents.get(id, 0))


## Kosten der nächsten Stufe; 0 = unbekannter Knoten oder Max-Level.
func talent_cost(id: StringName) -> int:
	if not TALENT_DEFS.has(id):
		return 0
	var level := talent_level(id)
	if level >= int(TALENT_DEFS[id]["max_level"]):
		return 0
	return roundi(float(TALENT_DEFS[id]["base_cost"]) * pow(1.35, level))


func talent_name(id: StringName) -> String:
	return str(TALENT_DEFS.get(id, {}).get("name", String(id)))


func talent_description(id: StringName) -> String:
	return str(TALENT_DEFS.get(id, {}).get("description", ""))


func talent_max_level(id: StringName) -> int:
	return int(TALENT_DEFS.get(id, {}).get("max_level", 0))


func buy_talent(id: StringName) -> bool:
	var cost := talent_cost(id)
	if cost <= 0 or gold < cost:
		return false
	gold -= cost
	talents[id] = talent_level(id) + 1
	_save()
	gold_changed.emit(gold)
	return true


## „Ahnensegen“: +5 Start-HP pro Stufe (Wirtschaft §3).
func start_hp_bonus() -> float:
	return 5.0 * talent_level(&"start_hp")


## „Glückshändler“: +5 % Gold pro Stufe (Playtesting §5.3: Soft-Cap +50 %).
func gold_rate_multiplier() -> float:
	return 1.0 + 0.05 * talent_level(&"gold_rate")


## „Wahrsagerei“: +1 Reroll pro Stufe (UI-UX §3: 3 Gratis-Rerolls als Basis).
func extra_rerolls() -> int:
	return talent_level(&"rerolls")


# ---------------------------------------------------------------------------
# Freischaltungen
# ---------------------------------------------------------------------------

func is_character_unlocked(id: StringName) -> bool:
	return id in unlocked_characters


func unlock_character(id: StringName) -> bool:
	if id in unlocked_characters:
		return false
	unlocked_characters.append(id)
	_save()
	return true


func is_region_unlocked(region_number: int) -> bool:
	return region_number in unlocked_regions


func unlock_region(region_number: int) -> bool:
	if region_number in unlocked_regions:
		return false
	unlocked_regions.append(region_number)
	unlocked_regions.sort()
	_save()
	return true


func has_defeated_boss(id: StringName) -> bool:
	return id in bosses_defeated


func mark_boss_defeated(id: StringName) -> bool:
	if id in bosses_defeated:
		return false
	bosses_defeated.append(id)
	_save()
	return true


# ---------------------------------------------------------------------------
# Persistenz (Technisches Konzept §6)
# ---------------------------------------------------------------------------

func save_game() -> void:
	_save()


func load_game() -> void:
	_reset_defaults()
	if not FileAccess.file_exists(SAVE_PATH):
		return  # Erster Start: Defaults, Datei entsteht beim ersten Speichern.
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_warning("MetaProgress: Save nicht lesbar (Fehler %d)." % FileAccess.get_open_error())
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file = null
	if not (parsed is Dictionary):
		push_warning("MetaProgress: save_data.json korrupt – Defaults werden geladen.")
		return
	var data: Dictionary = parsed
	var version := _to_int(data.get("save_version", 0))
	if version != SAVE_VERSION:
		# Versionsschütz (Technisches Konzept §6): unbekannten Stand nie
		# überschreiben, sondern vor dem Weitermachen als .bak sichern.
		push_warning("MetaProgress: Save-Version %d unbekannt (erwartet %d) – Stand als .bak gesichert, Defaults geladen." % [version, SAVE_VERSION])
		DirAccess.rename_absolute(
			ProjectSettings.globalize_path(SAVE_PATH),
			ProjectSettings.globalize_path(SAVE_PATH + ".v%d.bak" % version))
		return
	gold = _to_int(data.get("gold", 0))
	bernstein = _to_int(data.get("bernstein", 0))
	# Talente defensiv einlesen: nur bekannte Knoten, Werte auf [0, max].
	var raw_talents: Variant = data.get("talents", {})
	if raw_talents is Dictionary:
		for id: Variant in TALENT_DEFS:
			var key := StringName(str(id))
			talents[key] = clampi(
				_to_int((raw_talents as Dictionary).get(String(key), 0)),
				0, talent_max_level(key))
	unlocked_characters = _to_names(data.get("unlocked_characters"), DEFAULT_CHARACTERS)
	unlocked_regions = _to_region_numbers(data.get("unlocked_regions"), DEFAULT_REGIONS)
	bosses_defeated = _to_names(data.get("bosses_defeated", []), [])


func _save() -> void:
	var data := {
		"save_version": SAVE_VERSION,
		"gold": gold,
		"bernstein": bernstein,
		"talents": _talents_as_json(),
		"unlocked_characters": _names_as_strings(unlocked_characters),
		"unlocked_regions": unlocked_regions.duplicate(),
		"bosses_defeated": _names_as_strings(bosses_defeated),
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("MetaProgress: Save nicht schreibbar (Fehler %d)." % FileAccess.get_open_error())
		return
	file.store_string(JSON.stringify(data, "\t"))


func _reset_defaults() -> void:
	gold = 0
	bernstein = 0
	talents = {}
	for id: Variant in TALENT_DEFS:
		talents[StringName(str(id))] = 0
	unlocked_characters = DEFAULT_CHARACTERS.duplicate()
	unlocked_regions = DEFAULT_REGIONS.duplicate()
	bosses_defeated = []


# JSON-Hilfen: Godot parst alle Zahlen als float und Strings als String –
# für Save-Stabilität werden Typen hier explizit zurückgeführt.
func _to_int(value: Variant) -> int:
	if value is int or value is float:
		return roundi(float(value))
	return 0


func _to_names(value: Variant, fallback: Array[StringName]) -> Array[StringName]:
	var result: Array[StringName] = []
	if value is Array:
		for item: Variant in value:
			result.append(StringName(str(item)))
	# Leerstand = defekter/angegriffener Save: nicht zulassen, dass der
	# Spieler seine Charaktere verliert (Fallback = Start-Defaults).
	return fallback.duplicate() if result.is_empty() else result


func _to_region_numbers(value: Variant, fallback: Array[int]) -> Array[int]:
	var result: Array[int] = []
	if value is Array:
		for item: Variant in value:
			var number := _to_int(item)
			if number > 0 and not (number in result):
				result.append(number)
	if result.is_empty():
		return fallback.duplicate()
	result.sort()
	return result


func _talents_as_json() -> Dictionary:
	var out := {}
	for id: Variant in TALENT_DEFS:
		out[String(id)] = talent_level(StringName(str(id)))
	return out


func _names_as_strings(names: Array[StringName]) -> Array:
	var out := []
	for id: StringName in names:
		out.append(String(id))
	return out
