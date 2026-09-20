extends SceneTree
## Temporaerer Test M2c-1 (Danach loeschen): Domovoi-Fernkampf.
## Testet: Anflug -> Schussdistanz halten -> Schiessen -> Rueckzug.

var _main: Node
var _pool: Node
var _player: Node2D
var _frames := 0
var _ok := 0
var _fail := 0
var _domovoi: Node2D
var _shots_fired := 0
var _last_shot_pos := Vector2.ZERO
var _last_shot_dir := Vector2.ZERO
var _last_shot_speed := 0.0
var _last_shot_dmg := 0.0
var _retreat_start_dist := 0.0


func _check(label: String, cond: bool, detail: String) -> void:
	if cond:
		_ok += 1
	else:
		_fail += 1
	print("  [%s] %s - %s" % ["OK" if cond else "FEHLER", label, detail])


func _initialize() -> void:
	_main = load("res://scenes/main.tscn").instantiate()
	root.add_child(_main)
	current_scene = _main
	_pool = root.get_node_or_null("EnemyPoolManager")
	_player = _main.get_node("World/Player")


func _spawn_domovoi(pos: Vector2) -> Node2D:
	var e: Node2D = _pool.get_instance(&"ranged_enemies")
	e.max_hp = 300.0
	e.contact_damage = 9.0
	e.move_speed = 140.0
	e.target = _player
	e.global_position = pos
	e.set("_hp", 300.0)
	e.set("retreat_below", 90.0)
	e.set("preferred_orbit_radius", 190.0)
	e.fire_projectile = _on_fire
	return e


func _on_fire(pos: Vector2, dir: Vector2, speed: float, damage: float) -> void:
	_shots_fired += 1
	_last_shot_pos = pos
	_last_shot_dir = dir
	_last_shot_speed = speed
	_last_shot_dmg = damage


func _physics_process(_d: float) -> bool:
	_frames += 1
	if _frames < 60:
		return false
	if _frames == 60:
		_setup()
		return false
	if _frames == 300:
		_check_shots()
		_setup_retreat()
		return false
	if _frames == 330:
		_check_retreat()
		_finish()
		return true
	return false


func _setup() -> void:
	var director: Node = root.get_node_or_null("SpawnDirector")
	if director != null:
		director.set("region", null)
	var em: Node = root.get_node_or_null("EnemyPoolManager")
	em.call("return_all", &"enemies")
	em.call("return_all", &"enemy_projectiles")
	em.call("return_all", &"ranged_enemies")
	for entry in _main.inventory.weapons:
		(entry.node as WeaponBase).set_physics_process(false)
	_player.set_meta("arena_size", Vector2(4096, 4096))
	_player.global_position = Vector2(2048, 2048)
	_player.hp = 1000.0
	_player.max_hp = 1000.0
	# Domovoi weit weg (Anflug-Phase zuerst).
	_domovoi = _spawn_domovoi(Vector2(2048 + 500, 2048))


func _check_shots() -> void:
	print("--- TEST: SCHAETSEN aus Distanz ---")
	_check("Schuesse abgegeben (in 4 s)", _shots_fired >= 1, "%d Schuesse" % _shots_fired)
	_check("Projektil-Tempo uebergeben (320)", _last_shot_speed == 320.0, "%.0f px/s" % _last_shot_speed)
	_check("Schaden uebergeben (> 0)", _last_shot_dmg > 0.0, "%.1f Schaden" % _last_shot_dmg)
	var dist_now: float = _domovoi.global_position.distance_to(_player.global_position)
	_check("Domovoi haelt Schussdistanz", dist_now > 120.0,
		"%.0f px (Orbit-Soll ~190)" % dist_now)


func _setup_retreat() -> void:
	# Domovoi direkt an den Spieler setzen (unter Rueckzugsschwelle 90 px).
	_domovoi.global_position = _player.global_position + Vector2(60, 0)
	_retreat_start_dist = _domovoi.global_position.distance_to(_player.global_position)


func _check_retreat() -> void:
	print("--- TEST: RUECKZUG unter 90 px ---")
	var dist_now: float = _domovoi.global_position.distance_to(_player.global_position)
	_check("Domovoi weicht zurueck (> 90 px)", dist_now > _retreat_start_dist,
		"%.0f -> %.0f px" % [_retreat_start_dist, dist_now])


func _finish() -> void:
	print("--- M2c-1: %d OK / %d FEHLER ---" % [_ok, _fail])