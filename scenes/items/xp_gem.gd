extends Area2D
class_name XPGem
## XP-Gem (gepoolt). Wird von getöteten Gegnern gedroppt.
##
## Kollisions-Design (wichtig):
##   Der Gem erkennt selbst NICHTS (monitoring = false), er wird umgekehrt von
##   der MagnetArea des Spielers erkannt (die maskiert Layer 4). Beim Einsammeln
##   wird bewusst NICHT auf area_entered des Gems gewartet, sondern die Distanz
##   in _physics_process geprüft – das ist deterministisch und unabhängig davon,
##   wann Godot Kollisionspaare neu auswertet.

## Basis-Anziehung in px/s. Die 300 px/s aus dem technischen Setup reichten nicht:
## Durch stapelbare Speed-Upgrades kann der Spieler schneller werden und Gems
## dann „hinterherschleifen". Daher zusätzlich ein Sicherheitsaufschlag.
const BASE_ATTRACT_SPEED := 450.0
## Die Anziehung ist immer deutlich schneller als das Ziel selbst.
const ATTRACT_MARGIN_MULT := 1.6
const ATTRACT_MARGIN_ADD := 60.0
## Ab dieser Distanz zum Ziel gilt der Gem als eingesammelt.
const PICKUP_DISTANCE := 22.0

var value := 2.0
var target: Node2D

var _attracted := false


func _ready() -> void:
	collision_layer = 4
	collision_mask = 0
	monitoring = false
	monitorable = true


func _physics_process(delta: float) -> void:
	if not _attracted or target == null or not is_instance_valid(target):
		return
	var to_target := target.global_position - global_position
	var dist := to_target.length()
	if dist <= PICKUP_DISTANCE:
		_collect()
		return
	global_position += to_target / dist * _attract_speed() * delta


## Anziehungstempo: Basiswert, mindestens aber deutlich schneller als das Ziel,
## damit der Spieler Gems prinzipiell nicht davonlaufen kann.
func _attract_speed() -> float:
	var target_speed := 0.0
	if target != null and is_instance_valid(target):
		var s: Variant = target.get("speed")
		if (s is float) or (s is int):
			target_speed = float(s)
	return maxf(BASE_ATTRACT_SPEED, target_speed * ATTRACT_MARGIN_MULT + ATTRACT_MARGIN_ADD)


## Wird von der MagnetArea des Spielers aufgerufen.
func attract_to(node: Node2D) -> void:
	if _attracted:
		return
	_attracted = true
	target = node


func _collect() -> void:
	var collector := target
	# Vor der Pool-Rückgabe leeren, damit kein doppeltes Einsammeln möglich ist.
	_attracted = false
	target = null
	if collector != null and is_instance_valid(collector):
		collector.add_xp(value)
	EnemyPoolManager.return_instance(self)


## Pool-Schnittstelle.
func activate() -> void:
	_attracted = false
	target = null
	visible = true
	set_physics_process(true)
	set_deferred("monitorable", true)


## Pool-Schnittstelle.
func deactivate() -> void:
	_attracted = false
	target = null
	visible = false
	set_physics_process(false)
	set_deferred("monitorable", false)
	global_position = Vector2(-10000, -10000)
