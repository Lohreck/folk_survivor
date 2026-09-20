extends WeaponBase
class_name ThunderWeapon
## Donnerkeil – Blitz-Kettenschaden (M2b).
##
## Trifft das nächste Ziel in Reichweite und springt auf bis zu chain_count
## weitere Gegner (Kette). Kein Kegel, kein Nahkreis – rein zielgerichtet.

## Kettensprung-Reichweite (px) zwischen aufeinanderfolgenden Zielen.
const CHAIN_JUMP_RANGE := 160.0


func _perform_attack(target: Node2D) -> void:
	var hit := roll_damage()
	# Bereits getroffene Ziele mitführen, damit die Kette nicht zurückspringt.
	# Startvertiefung: Ziel MUSS in Reichweite sein (Verteidigung gegen Fremdaufruf).
	var visited: Array = []
	if target != null and is_instance_valid(target) and target.visible \
			and global_position.distance_squared_to(target.global_position) \
			<= data.attack_range * data.attack_range:
		_chain_damage(target, hit.amount, data.chain_count, visited)
	elif target != null:
		# Ziel außerhalb: von vorne suchen, sonst läuft ein Angriff ins Leere.
		var fallback := _nearest_to(global_position, visited)
		if fallback != null:
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
		_chain_damage(next, amount, chain_left - 1, visited)


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
