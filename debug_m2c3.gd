extends SceneTree
## Temporaerer Test M2c-3 (Danach loeschen): Leshy-Boss.
## Testet: Boss-Spawn bei Minute 10 -> Terrain-Warnung -> aktive Formation
## mit Schaden -> Boss-Sieg (Victory-Screen, Run-Ende).

var _main: Node
var _pool: Node
var _player: Node2D
var _frames := 0
var _ok := 0
var _fail := 0
var _boss: Node
var _hazard_pos := Vector2.ZERO
var _setup_done := false


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
	_player = _main.get_node("World/Player")


func _physics_process(_d: float) -> bool:
	_frames += 1
	if _frames < 60:
		return false
	if _frames == 60:
		_setup()
		return false
	if _frames == 90:
		if _check_spawn():
			_finish()
			return true
		return false
	if _frames == 210:
		# Spieler in den Hazard-Zonenmittelpunkt setzen (Warnphase ist nach
		# ~0.5 s aktiv; Boss-Spawn war bei Frame ~61, Aenderung nach 1 s,
		# Warnung 0.5 s -> aktiv ca. Frame 150).
		var hazard: Node2D = _boss.get("_active_hazard")
		if hazard != null and is_instance_valid(hazard):
			_player.global_position = hazard.global_position
		return false
	if _frames == 360:
		_check_hazard_damage()
		# Boss toeten -> Sieg muss ausgeloest werden.
		_boss.call("take_damage", 99999.0)
		return false
	if _frames == 390:
		_check_victory()
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
	# Boss-Spawn erzwingen: run_time 540 -> naechster Frame run_minute = 10.
	_main.set("run_time", 540.0)


func _check_spawn() -> bool:
	print("--- TEST: BOSS-SPAWN (Minute 10) ---")
	_boss = _main.get("_boss")
	_boss = _main.get("_boss")
	_check("Leshy gespawnt", _boss != null and is_instance_valid(_boss),
		str(_boss.name) if _boss != null else "null")
	if _boss == null:
		return true
	_check("Boss-HP fix (19000, keine Zeit-Skalierung)", _boss.get("max_hp") == 19000.0,
		"%.0f HP" % _boss.get("max_hp"))
	# Boss weit weg halten: kein Kontaktschaden, der den Hazard-Test stoert.
	_boss.set("move_speed", 0.0)
	_boss.global_position = _player.global_position + Vector2(700, 0)
	# Erste Terrain-Aenderung sofort (deterministisch statt 3 s Wartezeit).
	_boss.set("_terrain_timer", 0.0)
	return false


func _check_hazard_damage() -> void:
	print("--- TEST: TERRAIN-HAZARD ---")
	_check("Spieler hat Hazard-Schaden genommen", _player.hp < _player.max_hp,
		"%.0f / %.0f HP" % [_player.hp, _player.max_hp])


func _check_victory() -> void:
	var screen: Node = _main.get_node("HUD/DeathScreen")
	print("--- TEST: SIEG (Leshy besiegt) ---")
	_check("Sieg-Screen sichtbar", screen.visible, "visible = %s" % screen.visible)
	_check("Titel geaendert (Victory)", "Leshy" in str(screen.get_node("VBox/Title").text),
		str(screen.get_node("VBox/Title").text))
	_check("Run gestoppt", not _main.running, "running = %s" % str(_main.running))
	_check("Baum pausiert", paused, "get_tree().paused")


func _finish() -> void:
	print("--- M2c-3: %d OK / %d FEHLER ---" % [_ok, _fail])
