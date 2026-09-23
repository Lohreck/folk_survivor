extends WeaponBase
class_name AxeWeapon
## Axt des Holzfällers – Auto-Attack-Startwaffe (M2b).
##
## Trefferbereich = Front-Kegel (attack_range/half_arc) PLUS Nahbereich-Kreis
## (aoe_radius). Der Kreis fängt Kleber ab, die direkt am Spieler haften.
##
## Evolution „Uralteichen-Axt" (Waffen-Dokument §2.1): Radius verdoppelt,
## Knockback + Verwurzelt-Debuff (-30 % Tempo, 2 s).

@onready var _sweep: Node2D = $Sweep
@onready var _sweep_visual: Polygon2D = $Sweep/SweepVisual


func _ready() -> void:
	super._ready()
	_sweep_visual.visible = false


func _perform_attack(target: Node2D) -> void:
	_sweep_along((target.global_position - global_position).normalized())


## Twin-Stick: Schlag in Blickrichtung (Richtung unabhängig vom Ziel,
## Gate = Gegner in Reichweite, damit kein Schlag ins Leere).
func _perform_attack_along(aim: Vector2) -> bool:
	if _find_nearest_enemy() == null:
		return false
	_sweep_along(aim.normalized())
	return true


func _sweep_along(direction: Vector2) -> void:
	rotation = direction.angle()

	_sweep_visual.visible = true
	var hit := roll_damage()

	var close_r := data.aoe_radius
	var far_r := data.attack_range
	var arc := data.half_arc

	for enemy in enemy_container.get_children():
		if not enemy.visible:
			continue
		var to_enemy: Vector2 = enemy.global_position - global_position
		var dist := to_enemy.length()
		var hit_enemy := false
		if dist <= close_r:
			hit_enemy = true
		elif dist <= far_r:
			var angle_diff := absf(direction.angle_to(to_enemy))
			if angle_diff <= arc:
				hit_enemy = true

		if hit_enemy:
			enemy.take_damage(hit.amount)
			if evolved:
				# Uralteichen-Axt: Knockback + Verwurzelt.
				enemy.apply_knockback(global_position, 220.0)
				enemy.apply_root(2.0)

	_end_sweep.call_deferred()


func _on_evolved() -> void:
	# Visuelles Update: Sweep-Visual vergrößern (Radius verdoppelt).
	_sweep_visual.scale = Vector2(2.0, 2.0)


func _end_sweep() -> void:
	await get_tree().create_timer(0.12).timeout
	_sweep_visual.visible = false
