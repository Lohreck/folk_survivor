extends TestEnemy
class_name RangedEnemy
## Fernkampf-Gegner (M2c-1) – Basis für Domovoi (verdorben).
##
## Verhalten (Werte aus EnemyData: attack_range = 220, attack_cooldown = 2.2):
##   Nah (< retreat_below = 90 px):  Rückzug – weicht aus, um Schussdistanz zu halten
##   Ideal (90–220 px):              STEHT + schießt alle attack_cooldown s
##   Fern (> 220 px):                Anflug wie Nahkämpfer (Orbit-Logik der Basis)
##
## Erbt das komplette TestEnemy-Verhalten (Orbit, Separation, Debuffs,
## Knockback) und nutzt nur den _think_extra-Hook für die Schusslogik.

## Der Run injiziert diesen Callable (Projektil-Pool + Schaden):
## fire(pos, dir, speed, damage) -> void
var fire_projectile: Callable

## Projektil-Tempo (px/s). Genre-üblich: deutlich schneller als der Spieler,
## aber ausweichbar (Dodge bleibt der Kern-Skill).
const PROJECTILE_SPEED := 320.0

var _attack_timer := 0.0


func _ready() -> void:
	super._ready()
	# Fernkämpfer-Verhalten konfigurieren (Basis-Konstanten überschreiben).
	preferred_orbit_radius = 190.0
	retreat_below = 90.0
	_attack_timer = randf_range(0.4, 1.2)  # versetzte Schüsse im Schwarm


func setup_from_data(data: EnemyData, hp_mult: float, dmg_mult: float, elite: bool) -> void:
	super.setup_from_data(data, hp_mult, dmg_mult, elite)
	# Fernkampf-Werte aus der EnemyData übernehmen (Technisches Setup §6).
	set_meta("attack_range", data.attack_range)
	set_meta("attack_cooldown", data.attack_cooldown)
	set_meta("projectile_damage", contact_damage)
	_attack_timer = randf_range(0.4, 1.2)


func _think_extra(delta: float, target_dist: float, dir: Vector2) -> void:
	if _attack_timer > 0.0:
		_attack_timer -= delta
		return
	var ideal_range := float(get_meta("attack_range", 220.0))
	# Nur schießen, wenn das Ziel in Reichweite UND außerhalb des Rückzugs liegt.
	if target_dist > ideal_range or target_dist < retreat_below:
		return
	if not fire_projectile.is_valid():
		return
	var cooldown := float(get_meta("attack_cooldown", 2.2))
	var dmg := float(get_meta("projectile_damage", contact_damage))
	fire_projectile.call(global_position, dir, PROJECTILE_SPEED, dmg)
	_attack_timer = cooldown