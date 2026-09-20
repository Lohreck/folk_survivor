extends SceneTree
## Temporaerer Screenshot-Test (Danach loeschen): rendert echte Frames und
## speichert Screenshots, um Lesbarkeit zu beurteilen.

var _frames := 0
var _main: Node
var _shot_taken := 0


func _initialize() -> void:
	_main = load("res://scenes/main.tscn").instantiate()
	root.add_child(_main)
	current_scene = _main


func _physics_process(_d: float) -> bool:
	_frames += 1
	if _frames == 60:
		_setup()
	if _frames == 150:
		_shot("shot1_early.png")
	if _frames == 240:
		_shot("shot2_combat.png")
		return true
	return false


func _setup() -> void:
	var player: Node2D = _main.get_node("World/Player")
	player.set_meta("arena_size", Vector2(4096, 4096))
	player.global_position = Vector2(2048, 2048)
	player.hp = 1000.0
	player.max_hp = 1000.0
	var em: Node = root.get_node_or_null("EnemyPoolManager")
	var director: Node = root.get_node_or_null("SpawnDirector")
	director.set("region", null)
	# Szenen von Hand bestücken: 8 Kikimoras + 2 Domovoi + 2 Aitvaras.
	for i in 8:
		var e: Node2D = em.get_instance(&"enemies")
		e.setup_from_data(load("res://resources/enemies/kikimora.tres"), 1.0, 1.0, false)
		e.target = player
		e.on_died = Callable()
		e.global_position = player.global_position + Vector2.from_angle(TAU * i / 8.0) * randf_range(180, 320)
	for i in 2:
		var e: Node2D = em.get_instance(&"ranged_enemies")
		e.setup_from_data(load("res://resources/enemies/domovoi.tres"), 1.0, 1.0, false)
		e.target = player
		e.on_died = Callable()
		e.fire_projectile = _main._fire_enemy_projectile
		e.global_position = player.global_position + Vector2.from_angle(TAU * i / 2.0 + 0.4) * 320.0
	for i in 2:
		var e: Node2D = em.get_instance(&"flyer_enemies")
		e.setup_from_data(load("res://resources/enemies/aitvaras.tres"), 1.0, 1.0, false)
		e.target = player
		e.on_died = Callable()
		e.fire_projectile = _main._fire_enemy_projectile
		e.global_position = player.global_position + Vector2.from_angle(TAU * i / 2.0 + 1.9) * 260.0


func _shot(file: String) -> void:
	var img := root.get_viewport().get_texture().get_image()
	var dir := "/private/var/folders/by/kwv07z_x0ts25n9flfw1nvk80000gn/T/opencode/shots/"
	DirAccess.make_dir_recursive_absolute(dir)
	img.save_png(dir + file)
	_shot_taken += 1
	print("Screenshot: ", file, " (", img.get_width(), "x", img.get_height(), ")")