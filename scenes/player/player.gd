## Spieler-Figur (M1) – Werte aus Technisches Setup §3.1.
##
## Hinweis: Die Klasse hat bewusst kein class_name, da "Player" in Godot
## ein reservierter nativer Typ ist. Der Run referenziert sie per Node-Pfad.
extends Area2D
##
## - Bewegung per virtuellem Joystick (Mobile) oder WASD/Pfeiltasten (Desktop)
## - HP mit Treffer-Cooldown (0.5 s Invulnerabilität nach Treffer)
## - XP-Level: Signal level_up_ready bei Erreichen der nächsten Stufe
## - HP-Anzeige direkt an der Figur (UI/UX §2: kein separater HUD-Balken)

signal died
signal hp_changed(current: float, maximum: float)
signal level_up_ready

## Referenz-Charakter „Verbannte Soldat" (Balanced): 100 HP, 1.0× Tempo.
const BASE_SPEED := 200.0

@export var max_hp := 100.0
## Kontakt-Schadens-Cooldown (Technisches Setup §3.1).
@export var contact_cooldown := 0.5

var speed := BASE_SPEED
var hp := 100.0
var level := 1
var magnet_radius := 64.0
var alive := true

## XP-Schwelle zum nächsten Level (Balancing §7: round(6 × Level^1.5)).
## Startwert = Level 1 → 2 = 6 XP.
var xp_current := 0.0
var xp_to_next := 6.0

var _contact_timer := 0.0

@onready var _body: Polygon2D = $Body
@onready var _hp_bar_bg: ColorRect = $HpBar/Background
@onready var _hp_bar_fill: ColorRect = $HpBar/Fill
@onready var _magnet_shape: CollisionShape2D = $MagnetArea/CollisionShape2D
@onready var _hitbox: Area2D = $PlayerHitbox


func _ready() -> void:
	hp = max_hp
	collision_layer = 1
	collision_mask = 0
	(_magnet_shape.shape as CircleShape2D).radius = magnet_radius
	_update_hp_bar()


func _physics_process(delta: float) -> void:
	if not alive:
		return

	if _contact_timer > 0.0:
		_contact_timer -= delta

	# Bewegung: Joystick (Touch) hat Vorrang vor Tastatur.
	var dir := Vector2.ZERO
	if VirtualJoystickInput.active:
		dir = VirtualJoystickInput.get_output()
	if dir == Vector2.ZERO:
		dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	global_position += dir * speed * delta
	if has_meta("arena_size"):
		var arena: Vector2 = get_meta("arena_size")
		global_position = global_position.clamp(Vector2.ZERO, arena)

	if dir != Vector2.ZERO:
		rotation = dir.angle()

	_apply_contact_damage()


## Kontaktschaden: gepollt statt über area_entered, damit ein Gegner, der am
## Spieler klebt, nach Ablauf des Cooldowns erneut Schaden zufügt.
func _apply_contact_damage() -> void:
	if _contact_timer > 0.0:
		return
	for area in _hitbox.get_overlapping_areas():
		if area is TestEnemy:
			take_damage(area.contact_damage)
			return


func take_damage(amount: float) -> void:
	if not alive or _contact_timer > 0.0:
		return
	hp -= amount
	if hp < 0.0:
		hp = 0.0
	_contact_timer = contact_cooldown
	_body.modulate = Color(2.0, 0.5, 0.5)
	_reset_flash.call_deferred()
	hp_changed.emit(hp, max_hp)
	_update_hp_bar()
	if hp <= 0.0:
		alive = false
		died.emit()


func _reset_flash() -> void:
	await get_tree().create_timer(0.08).timeout
	if is_instance_valid(_body):
		_body.modulate = Color.WHITE


func _update_hp_bar() -> void:
	var ratio := clampf(hp / max_hp, 0.0, 1.0)
	_hp_bar_fill.size.x = _hp_bar_bg.size.x * ratio
	_hp_bar_fill.color = Color.GREEN.lerp(Color.RED, 1.0 - ratio)


func add_xp(amount: float) -> void:
	if not alive:
		return
	xp_current += amount
	while xp_current >= xp_to_next:
		xp_current -= xp_to_next
		level += 1
		# Balancing §7: XP_bis_naechstes_Level(L) = round(6 × L ^ 1.5).
		# M2a-Nachzug (M1 hatte eine flachere Platzhalterkurve, ×1.12).
		xp_to_next = roundf(6.0 * pow(float(level), 1.5))
		level_up_ready.emit()


## Setzt die max. HP (z. B. Leshy-Rinde-Passiv) und heilt den Zuwachs.
## Wird vom Run aufgerufen; kümmert sich selbst um HP-Bar und Signal.
func set_max_hp(new_max: float) -> void:
	if new_max <= max_hp:
		return
	var gained := new_max - max_hp
	max_hp = new_max
	hp = minf(hp + gained, max_hp)
	hp_changed.emit(hp, max_hp)
	_update_hp_bar()


## Heilt den Spieler (Level-Up-Fallback, wenn nichts mehr aufwertbar ist).
func heal(amount: float) -> void:
	if not alive:
		return
	hp = minf(hp + amount, max_hp)
	hp_changed.emit(hp, max_hp)
	_update_hp_bar()


## Setzt einen multiplikativen Tempo-Bonus (1.0 = Basis).
func set_speed_multiplier(mult: float) -> void:
	speed = BASE_SPEED * mult


## Setzt den Magnet-Radius (Pickup-Reichweite) inkl. Kollisionsform.
func set_magnet_radius(radius: float) -> void:
	magnet_radius = radius
	(_magnet_shape.shape as CircleShape2D).radius = radius


func regen_tick(delta: float) -> void:
	if not alive:
		return
	var regen: float = get_meta("run_stats")["hp_regen"]
	if regen > 0.0 and hp < max_hp:
		hp = minf(hp + regen * delta, max_hp)
		hp_changed.emit(hp, max_hp)
		_update_hp_bar()


func _on_magnet_area_area_entered(area: Area2D) -> void:
	# XPGem erkennt selbst nichts (monitoring = false) – er wird hier von der
	# MagnetArea erkannt (Magnet maskiert Layer 4, Gem ist monitorable).
	# Erkennung über die Methode, da XPGem bewusst kein class_name nutzt.
	if area.has_method("attract_to"):
		area.attract_to(self)
