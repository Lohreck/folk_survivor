extends WeaponBase
class_name PhioleWeapon
## Weihwasser-Phiole – Startwaffe der Kräuterfrau (Charaktere-Dokument §2.3).
##
## Wirft das Weihwasser nicht, sondern kippt es direkt: Flächen-Burst
## (aoe_radius) am Ziel-/Blickpunkt. Stärkster Flächen-Schaden des Start-
## Rosters (Start-DPS 14–16: 15 / 0.95 s ≈ 15.8, Charaktere §2.3), dafür
## ohne den Nahbereich-Kreis der Axt.
##
## Evolution „Loderndes Weihwasser“ (Waffen-Dokument §2.3) folgt mit M4 –
## evolution_id bleibt daher bewusst leer.

@onready var _burst: Polygon2D = $Burst


func _ready() -> void:
	super._ready()
	_burst.visible = false


## Polygon-Ring passend zum AOE-Radius bauen (Daten erst via setup() da).
func setup(weapon_data: WeaponData) -> void:
	super.setup(weapon_data)
	_burst.polygon = _circle_points(weapon_data.aoe_radius)


func _perform_attack(target: Node2D) -> void:
	_burst_at(target.global_position)


## Twin-Stick: Burst entlang der Blickrichtung in Waffen-Reichweite. Gate wie
## die Axt – kein Angriff, solange kein Ziel in Reichweite ist.
func _perform_attack_along(aim: Vector2) -> bool:
	if _find_nearest_enemy() == null:
		return false
	_burst_at(global_position + aim.normalized() * data.attack_range)
	return true


func _burst_at(center: Vector2) -> void:
	var hit := roll_damage()
	for enemy in enemy_container.get_children():
		if not enemy.visible:
			continue
		if enemy.global_position.distance_to(center) <= data.aoe_radius:
			enemy.take_damage(hit.amount * damage_bonus_vs(enemy))
	_burst.position = to_local(center)
	_burst.visible = true
	_end_burst.call_deferred()


func _end_burst() -> void:
	# Deferred-Aufruf kann nach Szenenwechsel ohne Baum ankommen – dann gibt
	# es keinen Timer mehr (get_tree() == null).
	if not is_inside_tree():
		return
	await get_tree().create_timer(0.12).timeout
	if is_instance_valid(_burst):
		_burst.visible = false


func _circle_points(radius: float, segments: int = 20) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in segments:
		points.append(Vector2.RIGHT.rotated(TAU * float(i) / float(segments)) * radius)
	return points
