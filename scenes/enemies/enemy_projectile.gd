extends Area2D
class_name EnemyProjectile
## Feindliches Projektil (M2c-1, gepoolt) – gerade Flugbahn, trifft Spieler.
##
## Kollisions-Design (spiegelbildlich zum XPGem):
##   Das Projektil erkennt selbst (monitoring = true, maskiert Layer 1 = Player)
##   und ist NICHT monitorable. Einsammeln/Treffer über area_entered.
##   Deaktivierung bei Treffer oder Ablauf der Lebenszeit (kein Endlospfeil).

## Flugtempo in px/s (wird vom Schützen gesetzt, Basis 320).
var speed := 320.0
## Schaden pro Treffer (bereits skaliert: Basis × Region × Zeit).
var damage := 9.0
## Flugrichtung (normalisiert).
var direction := Vector2.RIGHT

## Nach dieser Zeit in Sekunden verschwindet das Projektil (Lebenszeit-Schutz).
const MAX_LIFETIME := 4.0

var _lifetime := 0.0


func _ready() -> void:
	collision_layer = 8
	collision_mask = 1
	monitoring = true
	monitorable = false
	area_entered.connect(_on_area_entered)


func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	_lifetime += delta
	if _lifetime >= MAX_LIFETIME:
		EnemyPoolManager.return_instance(self)


## Wird vom Schützen (RangedEnemy via Callable) gesetzt.
func launch(pos: Vector2, dir: Vector2, proj_speed: float, proj_damage: float) -> void:
	global_position = pos
	direction = dir.normalized()
	speed = proj_speed
	damage = proj_damage
	_lifetime = 0.0
	rotation = direction.angle()
	visible = true
	set_physics_process(true)
	set_deferred("monitoring", true)


## Pool-Schnittstelle: Parken (unsichtbar, keine Prozesse, keine Kollision).
func deactivate() -> void:
	visible = false
	set_physics_process(false)
	set_deferred("monitoring", false)
	global_position = Vector2(-10000, -10000)


## Pool-Schnittstelle: Aktivieren.
func activate() -> void:
	visible = true
	set_physics_process(true)
	set_deferred("monitoring", true)


func _on_area_entered(area: Area2D) -> void:
	# Player hat add_xp-Methode NICHT, aber take_damage – Erkennung über Methode,
	# da die Player-Klasse bewusst kein class_name hat (Godot-Reservierung).
	if area.has_method("take_damage"):
		area.take_damage(damage)
		EnemyPoolManager.return_instance(self)