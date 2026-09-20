extends SceneTree
## Temporaerer Test M2c-2 (Danach loeschen): Aitvaras-Flieger.
## Testet: Anflug -> Orbit IN Schussreichweite -> Schiessen -> Schweben
##         -> Elite-Auswahl ab Minute 5 (Aitvaras-Gruppe).

var _main: Node
var _pool: Node
var _player: Node2D
var _frames := 0
var _ok := 0
var _fail := 0
var _aitvaras: Node2D
var _shots_fired := 0
var _last_shot_speed := 0.0
var _last_shot_dmg := 0.0
var _hover_sample_a := 0.0
var _hover_sample_b := 0.0


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


func _spawn_flyer(pos: Vector2) -> Node2D:
	var e: Node2D = _pool.get_instance(&"flyer_enemies")
	e.max_hp = 300.0
	e.contact_damage = 7.0
	e.move_speed = 200.0
	e.target = _player
	e.global_position = pos
	e.set("_hp", 300.0)
	e.set("preferred_orbit_radius", 150.0)
	e.set("retreat_below", 60.0)
	e.fire_projectile = _on_fire
	return e


func _on_fire(pos: Vector2, dir: Vector2, speed: float, damage: float) -> void:
	_shots_fired += 1
	_last_shot_speed = speed
	_last_shot_dmg = damage


func _physics_process(_d: float) -> bool:
	_frames += 1
	if _frames < 60:
		return false
	if _frames == 60:
		_setup()
		return false
	if _frames == 240:
		# Schweben: zwei Samples des Sprite-Offsets (muessen differieren,
		# wenn die Sinus-Bewegung laeuft).
		_hover_sample_a = _aitvaras.get_node("Body").position.y
		return false
	if _frames == 300:
		_hover_sample_b = _aitvaras.get_node("Body").position.y
		_check_shots()
		_finish()
		return true
	return false


func _setup() -> void:
	var director: Node = root.get_node_or_null("SpawnDirector")
	if director != null:
		director.set("region", null)
	var em: Node = root.get_node_or_null("EnemyPoolManager")
	em.call("return_all", &"enemies")
	em.call("return_all", &"ranged_enemies")
	em.call("return_all", &"flyer_enemies")
	em.call("return_all", &"enemy_projectiles")
	for entry in _main.inventory.weapons:
		(entry.node as WeaponBase).set_physics_process(false)
	_player.set_meta("arena_size", Vector2(4096, 4096))
	_player.global_position = Vector2(2048, 2048)
	_player.hp = 1000.0
	_player.max_hp = 1000.0
	# Aitvaras nah genug, damit der erste Schuss ins Testfenster faellt.
	_aitvaras = _spawn_flyer(Vector2(2048 + 300, 2048))


func _check_shots() -> void:
	print("--- TEST: FLIEGER-VERHALTEN AITVARAS ---")
	var dist_now: float = _aitvaras.global_position.distance_to(_player.global_position)
	_check("Aitvaras in Schussreichweite orbitiert", dist_now <= 180.0 and dist_now >= 60.0,
		"%.0f px (Band 60-180, Orbit-Soll 150)" % dist_now)
	_check("Schuesse abgegeben (in 3 s)", _shots_fired >= 1, "%d Schuesse" % _shots_fired)
	_check("Projektil-Tempo uebergeben (320)", _last_shot_speed == 320.0,
		"%.0f px/s" % _last_shot_speed)
	_check("Schaden uebergeben (> 0)", _last_shot_dmg > 0.0, "%.1f Schaden" % _last_shot_dmg)
	_check("Schweben sichtbar (Sprite-Bob)", absf(_hover_sample_a - _hover_sample_b) > 0.5,
		"%.1f -> %.1f px" % [_hover_sample_a, _hover_sample_b])
	print("--- TEST: ELITE-AUSWAHL (Balancing 3.3) ---")
	var em: Node = root.get_node_or_null("EnemyPoolManager")
	em.call("return_all", &"flyer_enemies")
	# Region laden (ist im _setup wegen der Spawnpauschale abgeschaltet).
	root.get_node_or_null("SpawnDirector").call("set_region",
		load("res://resources/regions/region_dammerwald.tres"))
	# Minute 5 erreicht -> Elite-Typ muss die Aitvaras-Gruppe sein.
	_main.set("run_minute", 5.2)
	var elite: EnemyData = _main.call("_pick_elite_type")
	_check("Erste Elite ab Minute 5 = Aitvaras",
		elite != null and elite.id == &"aitvaras",
		str(elite.id) if elite != null else "null")
	# Vor Minute 5: noch kein Elite-Kandidat aktiv -> Fallback = hoechste
	# Basis-HP im Mix (Domovoi, 22 HP).
	_main.set("run_minute", 4.0)
	var early: EnemyData = _main.call("_pick_elite_type")
	_check("Vor Minute 5 Fallback = hoechste HP (Domovoi)",
		early != null and early.id == &"domovoi",
		str(early.id) if early != null else "null")


func _finish() -> void:
	print("--- M2c-2: %d OK / %d FEHLER ---" % [_ok, _fail])
