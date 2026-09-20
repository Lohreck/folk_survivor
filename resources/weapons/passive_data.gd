class_name PassiveData
extends Resource
## Passiv-Item (Technisches Setup §6, Waffen-Dokument §3).
## Stat-Boni funktionieren OHNE die zugehörige Waffe (Waffen-Dokument §3 Hinweis).
## value_per_level hat max_level Einträge (Standard 5).

@export var id: StringName
@export var display_name: String
## Stat-Schlüssel, den der Player/das Inventar interpretiert:
## "max_hp_pct", "crit_chance", "area_damage_pct", "lifesteal_pct", "move_speed_pct"
@export var stat: StringName
## Werte pro Level in Prozentpunkten, z. B. [5, 10, 15, 20, 25].
@export var value_per_level: PackedFloat32Array = [5.0, 10.0, 15.0, 20.0, 25.0]
@export var max_level: int = 5
## Gehört zu dieser Evolution (leer = reines Stat-Item).
@export var evolution_weapon_id: StringName


## Bonus bei gegebenem Level. Die .tres-Werte sind ABSOLUTWERTE pro Level
## (Waffen-Dokument §3: Lv. 1 = +5 %, Lv. 5 = +25 %), keine Zuwächse.
func total_value_at(level: int) -> float:
	if level <= 0 or value_per_level.is_empty():
		return 0.0
	var index := mini(level, value_per_level.size()) - 1
	return value_per_level[index]
