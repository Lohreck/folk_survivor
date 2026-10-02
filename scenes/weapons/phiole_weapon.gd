extends WeaponBase
class_name PhioleWeapon
## Weihwasser-Phiole – Startwaffe der Kräuterfrau (Charaktere-Dokument §2.3).
##
## Wirft das Weihwasser nicht, sondern kippt es direkt: Flächen-Burst
## (aoe_radius) am Ziel-/Blickpunkt. Stärkster Flächen-Schaden des Start-
## Rosters (Start-DPS 14–16: 15 / 0.95 s ≈ 15.8, Charaktere §2.3), dafür
## ohne den Nahbereich-Kreis der Axt.
##
## Evolution „Loderndes Weihwasser“ (Waffen-Dokument §2.3, M4d): hinter dem
## Burst bleibt eine Brennzone (burn_duration) stehen, die pro Sekunde
## burn_dps_factor × Burst-Schaden macht und gegen Wasser-/Geist-Gegner
## doppelt trifft (bonus_tags).

@onready var _burst: Polygon2D = $Burst

## Brennzone (Loderndes Weihwasser): Restlaufzeit (s), DPS (Burst-Schaden ×
## burn_dps_factor × Aitvaras-Feder), Wurf-Weltzentrum und das Ring-Visual.
## Die Zone hängt am Waffen-Node (der am Spieler klebt), wird aber pro Frame
## auf das Wurfzentrum zurückgesetzt – sie wandert also NICHT mit.
var _burn_time_left := 0.0
var _burn_dps := 0.0
var _burn_center := Vector2.ZERO
var _burn_visual: Polygon2D


func _ready() -> void:
	super._ready()
	_burst.visible = false
	_burn_visual = Polygon2D.new()
	_burn_visual.color = Color(1.0, 0.45, 0.12, 0.4)
	_burn_visual.visible = false
	add_child(_burn_visual)


## Polygon-Ring passend zum AOE-Radius bauen (Daten erst via setup() da).
func setup(weapon_data: WeaponData) -> void:
	super.setup(weapon_data)
	_burst.polygon = _circle_points(weapon_data.aoe_radius)
	_burn_visual.polygon = _circle_points(weapon_data.aoe_radius)


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
			# Flächenschaden: Aitvaras-Feder skaliert den Burst, Bonus-Tags
			# (Loderndes Weihwasser vs. Wasser-/Geist-Gegner) kommen obendrauf.
			enemy.take_damage(hit.amount * damage_bonus_vs(enemy) \
				* area_mult() * element_bonus_vs(enemy))
	_burst.position = to_local(center)
	_burst.visible = true
	_start_burn(center, hit.amount)
	_end_burst.call_deferred()


## Loderndes Weihwasser (Waffen-Dok §2.3): Brennzone am Wurfzentrum für
## burn_duration Sekunden. Ohne Daten-Feld (Basis-Phiole) kein Opfer.
func _start_burn(center: Vector2, burst_amount: float) -> void:
	if data.burn_duration <= 0.0 or data.burn_dps_factor <= 0.0:
		return
	_burn_center = center
	_burn_time_left = data.burn_duration
	_burn_dps = burst_amount * data.burn_dps_factor * area_mult()
	_burn_visual.global_position = center
	_burn_visual.modulate.a = 1.0
	_burn_visual.visible = true


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if _burn_time_left <= 0.0:
		return
	_burn_time_left -= delta
	# Zone bleibt am Wurfzentrum, auch wenn der Spieler weiterläuft.
	_burn_visual.global_position = _burn_center
	# Ausblend-Je näher das Ende, desto schwächer der Ring (lesbares Feedback).
	_burn_visual.modulate.a = clampf(_burn_time_left / data.burn_duration, 0.0, 1.0)
	if enemy_container != null:
		var tick := _burn_dps * delta
		for enemy in enemy_container.get_children():
			if not enemy.visible or not enemy.has_method("take_damage"):
				continue
			if enemy.global_position.distance_to(_burn_center) <= data.aoe_radius:
				enemy.take_damage(tick * damage_bonus_vs(enemy) * element_bonus_vs(enemy))
	if _burn_time_left <= 0.0:
		_burn_visual.visible = false


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
