class_name RunInventory
extends RefCounted
## Run-Inventar: Waffen- & Passiv-Slots mit Level-Verwaltung.
## Evolution-Bedingung (Waffen-Dokument §1): Waffe Lv. 8 + Passiv Lv. 5
## → beim nächsten Level-Up-Fenster wird die Evolutions-Karte angeboten.

const MAX_WEAPON_SLOTS := 5
const MAX_PASSIVE_SLOTS := 5

## Einträge: {data: WeaponData, level: int, node: Node2D, evolved: bool}
var weapons: Array = []
## Einträge: {data: PassiveData, level: int}
var passives: Array = []


func weapon_by_id(id: StringName) -> Dictionary:
	for entry in weapons:
		if (entry.data as WeaponData).id == id:
			return entry
	return {}


func weapon_level(id: StringName) -> int:
	var entry := weapon_by_id(id)
	return entry.get("level", 0) if not entry.is_empty() else 0


func passive_level(id: StringName) -> int:
	for entry in passives:
		if (entry.data as PassiveData).id == id:
			return entry.level
	return 0


## Summierter Passiv-Bonus für einen Stat-Schlüssel (z. B. "crit_chance").
func passive_total(stat: StringName) -> float:
	var total := 0.0
	for entry in passives:
		var data: PassiveData = entry.data
		if data.stat == stat:
			total += data.total_value_at(entry.level)
	return total


func add_weapon(data: WeaponData, node: Node2D) -> void:
	weapons.append({"data": data, "level": 1, "node": node, "evolved": false})


func add_passive(data: PassiveData) -> void:
	passives.append({"data": data, "level": 1})


func upgrade_weapon(id: StringName) -> bool:
	var entry := weapon_by_id(id)
	if entry.is_empty() or entry.level >= (entry.data as WeaponData).max_level:
		return false
	entry.level += 1
	return true


func upgrade_passive(id: StringName) -> bool:
	for entry in passives:
		if (entry.data as PassiveData).id == id:
			if entry.level >= (entry.data as PassiveData).max_level:
				return false
			entry.level += 1
			return true
	return false


## Evolution-Bedingung erfüllt? (Waffe Lv. 8, Passiv Lv. 5, noch nicht evolviert)
func can_evolve(data: WeaponData) -> bool:
	if data.evolution_id.is_empty():
		return false
	var entry := weapon_by_id(data.id)
	if entry.is_empty() or entry.level < data.max_level or entry.evolved:
		return false
	return passive_level(data.required_passive_id) >= 5


## Führt die Evolution durch: Waffe kriegt die Evolution-Data, bleibt auf Max-Level.
func evolve(data: WeaponData, evolved_data: WeaponData) -> void:
	var entry := weapon_by_id(data.id)
	if entry.is_empty():
		return
	entry.data = evolved_data
	entry.evolved = true


## Erzeugt die Upgrade-Optionen für den Level-Up-Screen.
## Alle Waffen/Passivs mit Level < Max, freie Slots für Neues, Evolution (gold).
## Rückgabe: Array von Dictionaries {kind, id, title, desc, icon_color, is_evolution}
func build_upgrade_options(all_weapons: Array, all_passives: Array) -> Array:
	var options: Array = []

	# 1) Evolutionen zuerst (höchste Priorität, goldene Karte).
	for entry in weapons:
		var data: WeaponData = entry.data
		if can_evolve(data):
			options.append({
				"kind": "evolve", "id": data.id,
				"title": "EVOLUTION: %s" % _evolved_name(data),
				"desc": "Struktureller Sprung – Waffe wandelt sich",
				"icon_color": Color(1.0, 0.85, 0.25), "is_evolution": true,
			})

	# 2) Waffen-Level-Ups.
	for entry in weapons:
		var data: WeaponData = entry.data
		if entry.level < data.max_level:
			options.append({
				"kind": "weapon_up", "id": data.id,
				"title": "%s +1" % data.display_name,
				"desc": "Schaden ×1.3 (Lv. %d → %d)" % [entry.level, entry.level + 1],
				"icon_color": Color(0.9, 0.3, 0.25), "is_evolution": false,
			})

	# 3) Passiv-Level-Ups.
	for entry in passives:
		var data: PassiveData = entry.data
		if entry.level < data.max_level:
			options.append({
				"kind": "passive_up", "id": data.id,
				"title": "%s +1" % data.display_name,
				"desc": "%s-Bonus steigt (Lv. %d → %d)" % [data.display_name, entry.level, entry.level + 1],
				"icon_color": Color(0.75, 0.4, 0.95), "is_evolution": false,
			})

	# 4) Neue Waffen, solange Slots frei sind.
	if weapons.size() < MAX_WEAPON_SLOTS:
		for data: WeaponData in all_weapons:
			if weapon_by_id(data.id).is_empty():
				options.append({
					"kind": "new_weapon", "id": data.id,
					"title": "NEU: %s" % data.display_name,
					"desc": "Neue Waffe (Lv. 1)",
					"icon_color": Color(0.35, 0.6, 0.95), "is_evolution": false,
				})

	# 5) Neue Passivs, solange Slots frei sind.
	if passives.size() < MAX_PASSIVE_SLOTS:
		for data: PassiveData in all_passives:
			var known := false
			for entry in passives:
				if (entry.data as PassiveData).id == data.id:
					known = true
			if not known:
				options.append({
					"kind": "new_passive", "id": data.id,
					"title": "NEU: %s" % data.display_name,
					"desc": "Neues Passiv-Item (Lv. 1)",
					"icon_color": Color(0.4, 0.95, 0.7), "is_evolution": false,
				})

	return options


func _evolved_name(data: WeaponData) -> String:
	# Evolution-Name aus der Inventory-Map der Main (Fallback: generisch).
	match data.evolution_id:
		&"uralteichen_axt":
			return "Uralteichen-Axt"
		&"todesschnitt":
			return "Todesschnitt"
		&"peruns_zorn":
			return "Peruns Zorn"
		_:
			return "Evolution"

