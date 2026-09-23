extends Node2D
class_name WeaponBase
## Gemeinsame Basis aller Waffen (M2b).
##
## Trägt: WeaponData (aus .tres), Level, DPS-Kurve (Balancing §8), Krit-Chance
## (Perun-Amulett), Cooldown-Handling und die Auto-Attack-Logik. Konkrete Waffen
## (Axt, Sichel, Donnerkeil) erben und überschreiben _perform_attack().

## Die geladene WeaponData-Resource (vom Run beim Spawn gesetzt).
var data: WeaponData
## Aktuelles Level (1–8).
var level := 1
## Schadens-Multiplikator aus den Run-Stats (Schaden+-Upgrades).
var damage_mult := 1.0
## Cooldown-Multiplikator aus den Run-Stats (Tempo+-Upgrades).
var cooldown_mult := 1.0
## Krit-Chance in Prozent (Perun-Amulett), doppelter Schaden bei Krit.
var crit_chance_pct := 0.0
## Wurde diese Waffe evolviert? (ändert strukturell die Wirkweise)
var evolved := false

## Referenz auf den Container mit den Gegnern (wird vom Run gesetzt).
var enemy_container: Node2D
## Referenz auf den Spieler (Besitzer der Waffe).
var owner_node: Node2D

var _cooldown_timer := 0.0


func _ready() -> void:
	set_process(false)  # Waffe läuft nur, wenn sie konfiguriert ist.


## Konfiguriert die Waffe aus ihrer WeaponData. Vom Run direkt nach add_child.
func setup(weapon_data: WeaponData) -> void:
	data = weapon_data
	level = 1
	evolved = false
	_cooldown_timer = 0.0
	set_process(true)
	set_physics_process(true)


## DPS-Kurve: base_damage × 1.30^(level-1) (Balancing §8).
func damage_at_current_level() -> float:
	return data.damage_for_level(level)


## Endgültiger Trefferschaden inkl. Run-Multiplikatoren und Krit-Roll.
## Rückgabe: Dictionary {amount, is_crit}.
func roll_damage() -> Dictionary:
	var amount := damage_at_current_level() * damage_mult
	var is_crit := false
	if crit_chance_pct > 0.0 and randf() * 100.0 < crit_chance_pct:
		is_crit = true
		amount *= 2.0
	return {"amount": amount, "is_crit": is_crit}


## Steigert das Level (bis max_level). Vom Level-Up-Screen aufgerufen.
func level_up() -> void:
	if level < data.max_level:
		level += 1
		_on_level_changed()


## Wendet die Evolution an (M2b: Uralteichen-Axt). Vom Run aufgerufen.
func apply_evolution(evolved_data: WeaponData) -> void:
	data = evolved_data
	evolved = true
	level = data.max_level
	_on_evolved()


## Hooks für Unterklassen.
func _on_level_changed() -> void:
	pass


func _on_evolved() -> void:
	pass


func _physics_process(delta: float) -> void:
	if owner_node == null or not is_instance_valid(owner_node) or data == null:
		return
	# Waffe klebt am Spieler.
	global_position = owner_node.global_position

	_cooldown_timer -= delta
	if _cooldown_timer <= 0.0:
		# Twin-Stick: Mit gehaltener Zielrichtung entlang der Blickrichtung
		# angreifen, sonst Auto-Modus auf den nächstgelegenen Gegner.
		var aim := _manual_aim()
		if aim != Vector2.ZERO:
			if _perform_attack_along(aim):
				_cooldown_timer = data.cooldown * cooldown_mult
		else:
			var target := _find_nearest_enemy()
			if target != null:
				_perform_attack(target)
				_cooldown_timer = data.cooldown * cooldown_mult


## Überschrieben von der konkreten Waffe (Auto-Modus).
func _perform_attack(target: Node2D) -> void:
	pass


## Angriff entlang der manuellen Blickrichtung (Twin-Stick). Gate:
## mindestens ein Gegner in Reichweite – sonst schlägt die Waffe nicht ins
## Leere. Rückgabe false = nicht angegriffen (Cooldown bleibt erhalten).
## Konkrete Waffen überschreiben für eigene Ziel-Auswahl (z. B. Donnerkeil
## einen Kegel um die Blickrichtung).
func _perform_attack_along(aim: Vector2) -> bool:
	var target := _find_nearest_enemy()
	if target == null:
		return false
	_perform_attack(target)
	return true


## Manuelle Zielrichtung des Besitzers oder ZERO = Auto-Modus.
func _manual_aim() -> Vector2:
	if owner_node != null and is_instance_valid(owner_node) \
			and owner_node.has_method("get_aim_direction"):
		return owner_node.get_aim_direction()
	return Vector2.ZERO


## Nächsten Gegner in Reichweite finden (Kegel-Reichweite).
func _find_nearest_enemy() -> Node2D:
	if enemy_container == null:
		return null
	var nearest: Node2D = null
	var nearest_dist := data.attack_range * data.attack_range
	for enemy in enemy_container.get_children():
		if not enemy.visible:
			continue
		var dist := global_position.distance_squared_to(enemy.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = enemy
	return nearest
