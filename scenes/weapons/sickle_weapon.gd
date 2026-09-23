extends WeaponBase
class_name SickleWeapon
## Sichel – schneller Nahkampf mit breitem Kegel + Blutung (M2b).
##
## Kein separater Nahkreis (aoe_radius == attack_range): trifft alles
## im 137°-Kegel vor dem Spieler. Blutung (DoT) auf getroffene Gegner.

@onready var _sweep: Node2D = $Sweep
@onready var _sweep_visual: Polygon2D = $Sweep/SweepVisual


func _ready() -> void:
	super._ready()
	_sweep_visual.visible = false


func _perform_attack(target: Node2D) -> void:
	_sweep_along((target.global_position - global_position).normalized())


## Twin-Stick: Kegelschlag in Blickrichtung (Gate = Gegner in Reichweite).
func _perform_attack_along(aim: Vector2) -> bool:
	if _find_nearest_enemy() == null:
		return false
	_sweep_along(aim.normalized())
	return true


func _sweep_along(direction: Vector2) -> void:
	rotation = direction.angle()

	_sweep_visual.visible = true
	var hit := roll_damage()

	var range_r := data.attack_range
	var arc := data.half_arc

	for enemy in enemy_container.get_children():
		if not enemy.visible:
			continue
		var to_enemy: Vector2 = enemy.global_position - global_position
		if to_enemy.length() > range_r:
			continue
		var angle_diff := absf(direction.angle_to(to_enemy))
		if angle_diff <= arc:
			enemy.take_damage(hit.amount)
			# Blutung: DoT = bleed_pct × Trefferschaden, über 3 s.
			enemy.apply_bleed(hit.amount * data.bleed_pct, 3.0)

	_end_sweep.call_deferred()


func _end_sweep() -> void:
	await get_tree().create_timer(0.12).timeout
	_sweep_visual.visible = false
