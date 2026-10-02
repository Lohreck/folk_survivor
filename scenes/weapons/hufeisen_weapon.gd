extends WeaponBase
class_name HufeisenWeapon
## Eisernes Hufeisen – Wurf/Boomerang (Technisches Setup §3.3: 14 Schaden,
## 1.2 s Cooldown, 260 px Reichweite, 400 px/s, „kehrt zurück").
##
## Flug-Zustandsmaschine: OUT (herausgeworfen) → erster Treffer ODER
## Max-Reichweite → RETURN (Rückflug zum Besitzer) → IDLE (hängt wieder am
## Spieler, kein sichtbares Sprite). Evolution „Segenshufeisen"
## (Waffen-Dokument §2.2): data.pierce lässt den Wurf alle Gegner
## durchdringen, bevor er zurückkehrt.

## Flug-Tempo in px/s (Technisches Setup §3.3 Waffentabelle).
const FLIGHT_SPEED := 400.0
## Treffer-Radius beim Vorbeifliegen in px.
const HIT_RADIUS := 20.0
## Abstand, in dem der Rückflug am Besitzer andockt (px).
const _RETURN_SNAP := 10.0
## Leichte Nachführung nur im Auto-Modus (Kegel um die Wurfrichtung) –
## manuelle Würfe fliegen gerade, damit die Zielrichtung des Spielers zählt.
const _AUTO_HOMING_CONE := 0.35
## Nachführung pro Physik-Frame im Auto-Modus.
const _AUTO_HOMING_PULL := 0.12

enum _State { IDLE, OUT, RETURN }

var _state := _State.IDLE
var _flight_dir := Vector2.RIGHT
var _traveled := 0.0
var _homing := false
var _visited: Array = []
var _hit_amount := 0.0

@onready var _shoe: Polygon2D = $Shoe


func _ready() -> void:
	super._ready()
	_shoe.visible = false
	_shoe.polygon = _horseshoe_points()


func _physics_process(delta: float) -> void:
	if data == null:
		return
	if _state == _State.IDLE:
		# Ruhezustand: am Spieler kleben + Cooldown + Angriffs-Auslösung.
		super._physics_process(delta)
		return
	if owner_node == null or not is_instance_valid(owner_node):
		return
	# Der Cooldown tickt während des Flugs weiter – die Wurfdauer zählt zur
	# Feuerrate, nach der Landung kann sofort neu geworfen werden.
	_cooldown_timer -= delta
	var step := FLIGHT_SPEED * delta
	if _state == _State.OUT:
		if _homing:
			_flight_dir = _homing_step(_flight_dir)
		global_position += _flight_dir * step
		_traveled += step
		_check_hits()
		if _state == _State.OUT and _traveled >= data.attack_range:
			_state = _State.RETURN
	else:
		var to_owner: Vector2 = owner_node.global_position - global_position
		if to_owner.length() <= _RETURN_SNAP:
			_land()
		else:
			global_position += to_owner.normalized() * step
	rotation += 12.0 * delta


func _perform_attack(target: Node2D) -> void:
	# Auto-Modus: mit leichter Nachführung, sonst läuft das Hufeisen an
	# orbitierenden Gegnern vorbei und die Decke fällt ins Leere.
	_throw((target.global_position - global_position).normalized(), true)


## Twin-Stick: Wurf in Blickrichtung. Gate wie die anderen Waffen – kein
## Angriff, solange kein Ziel in Reichweite ist.
func _perform_attack_along(aim: Vector2) -> bool:
	if _find_nearest_enemy() == null:
		return false
	_throw(aim.normalized(), false)
	return true


## Wirft das Hufeisen in die angegebene Richtung.
func _throw(dir: Vector2, homing: bool) -> void:
	_state = _State.OUT
	_flight_dir = dir
	_traveled = 0.0
	_homing = homing
	_visited.clear()
	_hit_amount = roll_damage().amount
	_shoe.visible = true


## Treffer-Check entlang des Flugwegs. Ohne data.pierce stoppt der Wurf
## beim ersten Treffer (Basis-Verhalten Technisches Setup §3.3).
func _check_hits() -> void:
	if enemy_container == null:
		return
	for enemy in enemy_container.get_children():
		if not enemy.visible or enemy in _visited:
			continue
		if not enemy.has_method("take_damage"):
			continue  # Effekt-Nodes (Blitz-Segmente) sind keine Gegner
		if global_position.distance_squared_to(enemy.global_position) \
				> HIT_RADIUS * HIT_RADIUS:
			continue
		_visited.append(enemy)
		# Bonus-Tags (Segenshufeisen: Hausgeist-Typ, Waffen-Dok §2.2).
		enemy.take_damage(_hit_amount * damage_bonus_vs(enemy) * element_bonus_vs(enemy))
		if not data.pierce:
			_state = _State.RETURN
			return


## Auto-Modus: sanfte Nachführung auf den nächsten noch nicht getroffenen
## Gegner, sofern dieser ungefähr in Wurfrichtung liegt – manuelle Würfe
## bleiben davon unberührt.
func _homing_step(dir: Vector2) -> Vector2:
	var best: Node2D = null
	var best_dist := INF
	for enemy in enemy_container.get_children():
		if not enemy.visible or enemy in _visited:
			continue
		if not enemy.has_method("take_damage"):
			continue
		var dist := global_position.distance_squared_to(enemy.global_position)
		if dist < best_dist:
			best_dist = dist
			best = enemy
	if best == null:
		return dir
	var to_target: Vector2 = (best.global_position - global_position).normalized()
	if absf(dir.angle_to(to_target)) > _AUTO_HOMING_CONE:
		return dir
	return dir.slerp(to_target, _AUTO_HOMING_PULL).normalized()


func _land() -> void:
	_state = _State.IDLE
	global_position = owner_node.global_position
	_visited.clear()
	_shoe.visible = false


## Hufeisen-Form: halber Ring (Außen- + Innenradius), Öffnung nach oben.
func _horseshoe_points() -> PackedVector2Array:
	var points := PackedVector2Array()
	var segments := 14
	var outer := 15.0
	var inner := 8.0
	for i in segments + 1:
		var angle := PI * float(i) / float(segments)
		points.append(Vector2(cos(angle), sin(angle)) * outer)
	for i in range(segments, -1, -1):
		var angle := PI * float(i) / float(segments)
		points.append(Vector2(cos(angle), sin(angle)) * inner)
	return points
