extends WeaponBase
class_name ThunderWeapon
## Donnerkeil – Blitz-Kettenschaden (M2b).
##
## Trifft das nächste Ziel in Reichweite und springt auf bis zu chain_count
## weitere Gegner (Kette). Kein Kegel, kein Nahkreis – rein zielgerichtet.

## Kettensprung-Reichweite (px) zwischen aufeinanderfolgenden Zielen.
const CHAIN_JUMP_RANGE := 160.0

## Blitz-Visual: Dauer (s) und Farbe der Kettenlinie.
const _BOLT_TIME := 0.14
const _BOLT_COLOR := Color(1.0, 0.95, 0.45, 0.9)


func _perform_attack(target: Node2D) -> void:
	var hit := roll_damage()
	# Bereits getroffene Ziele mitführen, damit die Kette nicht zurückspringt.
	# Startvertiefung: Ziel MUSS in Reichweite sein (Verteidigung gegen Fremdaufruf).
	var visited: Array = []
	if target != null and is_instance_valid(target) and target.visible \
			and global_position.distance_squared_to(target.global_position) \
			<= data.attack_range * data.attack_range:
		_draw_bolt(global_position, target.global_position)
		_chain_damage(target, hit.amount, data.chain_count, visited)
	elif target != null:
		# Ziel außerhalb: von vorne suchen, sonst läuft ein Angriff ins Leere.
		var fallback := _nearest_to(global_position, visited)
		if fallback != null:
			_draw_bolt(global_position, fallback.global_position)
			_chain_damage(fallback, hit.amount, data.chain_count, visited)


## Springt von current zum nächstgelegenen NOCH NICHT getroffenen Gegner.
## WICHTIG: Der Sprungradius misst die Distanz zum LETZTEN Treffer (Kettenlinie),
## nicht zur Waffe – sonst läuft die Kette gegen die Marschrichtung ins Leere.
func _chain_damage(current: Node2D, amount: float, chain_left: int, visited: Array) -> void:
	if current == null or not is_instance_valid(current) or not current.visible or current in visited:
		return
	visited.append(current)
	current.take_damage(amount)
	if chain_left <= 0:
		return
	# Nächstes Ziel ab der Position des LETZTEN Treffers (Kettenlinie entlang).
	var next := _nearest_to(current.global_position, visited)
	if next != null:
		_draw_bolt(current.global_position, next.global_position)
		_chain_damage(next, amount, chain_left - 1, visited)


## Sichtbarer Blitz-Segmente (Angriff-Feedback-Prinzip: Angriffe müssen
## lesbar sein – Playtest-Feedback M2c: „Angriffe schwer zu erahnen").
## Die Line2D hängt auf Position (0,0) im EnemyContainer, Punkte sind global.
func _draw_bolt(from_pos: Vector2, to_pos: Vector2) -> void:
	var bolt := Line2D.new()
	bolt.width = 3.0
	bolt.default_color = _BOLT_COLOR
	var mid := (from_pos + to_pos) * 0.5 + Vector2(randf_range(-14, 14), randf_range(-14, 14))
	bolt.points = PackedVector2Array([from_pos, mid, to_pos])
	bolt.z_index = 50
	enemy_container.add_child(bolt)
	_fade_bolt.call_deferred(bolt)


func _fade_bolt(bolt: Line2D) -> void:
	await get_tree().create_timer(_BOLT_TIME).timeout
	if bolt != null and is_instance_valid(bolt):
		bolt.queue_free()


## Nächster Gegner im Kettenradius, der noch nicht getroffen wurde.
func _nearest_to(pos: Vector2, visited: Array) -> Node2D:
	if enemy_container == null:
		return null
	var nearest: Node2D = null
	var nearest_dist := CHAIN_JUMP_RANGE * CHAIN_JUMP_RANGE
	for enemy in enemy_container.get_children():
		if not enemy.visible or enemy in visited:
			continue
		var dist := pos.distance_squared_to(enemy.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = enemy
	return nearest
