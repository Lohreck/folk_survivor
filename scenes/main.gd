extends Node2D
## Meilenstein 2b – Waffen, Passivs, erste Evolution.
##
## Baut auf M2a auf: Ersetzt die M1-Platzhalter-Upgrades durch das echte
## Run-Inventar (Waffen-Slots 5, Passiv-Slots 5, Waffen-Dokument §1).
## Waffen: Axt, Sichel, Donnerkeil (Lv. 1–8, DPS ×1.30/Lv., Balancing §8).
## Passivs: Leshy-Rinde, Perun-Amulett (Stat-Boni, auch ohne Waffe nutzbar).
## Erste Evolution: Axt Lv. 8 + Leshy-Rinde Lv. 5 → Uralteichen-Axt.

const ENEMY_SCENE := preload("res://scenes/enemies/test_enemy.tscn")
const RANGED_ENEMY_SCENE := preload("res://scenes/enemies/ranged_enemy.tscn")
const FLYER_ENEMY_SCENE := preload("res://scenes/enemies/flyer_enemy.tscn")
const ENEMY_PROJECTILE_SCENE := preload("res://scenes/enemies/enemy_projectile.tscn")
const GEM_SCENE := preload("res://scenes/items/xp_gem.tscn")
const REGION_SCENE := preload("res://resources/regions/region_dammerwald.tres")
const AXE_SCENE := preload("res://scenes/weapons/axe_weapon.tscn")
const SICKLE_SCENE := preload("res://scenes/weapons/sickle_weapon.tscn")
const THUNDER_SCENE := preload("res://scenes/weapons/thunder_weapon.tscn")
const AXE_DATA := preload("res://resources/weapons/axe_holzfaenger.tres")
const SICKLE_DATA := preload("res://resources/weapons/sichel.tres")
const THUNDER_DATA := preload("res://resources/weapons/donnerkeil.tres")
const LESHY_DATA := preload("res://resources/weapons/leshy_rinde.tres")
const PERUN_DATA := preload("res://resources/weapons/perun_amulett.tres")
const URALTEICHEN_DATA := preload("res://resources/weapons/uralteichen_axt.tres")
const BOSS_SCENE := preload("res://scenes/enemies/leshy_boss.tscn")
const BOSS_DATA := preload("res://resources/enemies/leshy.tres")
const ARENA_SIZE := Vector2(4096, 4096)

const POOL_ENEMIES: StringName = &"enemies"
const POOL_RANGED: StringName = &"ranged_enemies"
const POOL_FLYERS: StringName = &"flyer_enemies"
const POOL_GEMS: StringName = &"xp_gems"
const POOL_PROJECTILES: StringName = &"enemy_projectiles"

## Upgrade-Pool: entfällt in M2b – Optionen kommen aus dem Run-Inventar
## (Waffen/Passivs mit Leveln, Evolution ab Lv. 8 + Lv. 5).

@onready var player: Area2D = $World/Player
@onready var enemy_container: Node2D = $World/EnemyContainer
@onready var gem_container: Node2D = $World/GemContainer
@onready var weapon_container: Node2D = $World/WeaponContainer
@onready var _projectile_container: Node2D = $World/ProjectileContainer
@onready var camera: Camera2D = $World/Player/Camera2D
@onready var atmosphere: CanvasModulate = $Atmosphere
@onready var player_light: PointLight2D = $World/Player/PlayerLight
@onready var fireflies: CPUParticles2D = $Fireflies
@onready var vignette_shade: Sprite2D = $Vignette/Shade
@onready var fog: Sprite2D = $FogLayer/Fog

@onready var xp_bar: ProgressBar = $HUD/XpBar
@onready var time_label: Label = $HUD/TimeLabel
@onready var level_label: Label = $HUD/LevelLabel
@onready var fps_label: Label = $HUD/FpsLabel
@onready var kills_label: Label = $HUD/KillsLabel
@onready var death_screen: DeathScreen = $HUD/DeathScreen
@onready var boss_bar: ProgressBar = $HUD/BossBar
@onready var level_up_screen: CanvasLayer = $LevelUpScreen

var run_time := 0.0
var kills := 0
var running := true

## Uniform-Grid für die Gegner-Separation (O(1) pro Gegner, kein N²-Loop).
const _ENEMY_GRID_CELL := 40
var _enemy_grid: Dictionary = {}

## Spawn-Steuerung: übernimmt jetzt der SpawnDirector (Balancing-Formeln).
## Aktive Run-Minute (für die Kurven, fraktional – 2.5 = Mitte Minute 2–3).
var run_minute := 1.0
## Run-Inventar (Waffen + Passivs mit Leveln, M2b).
var inventory := RunInventory.new()
## Alle verfügbaren Waffen/Passivs (Daten-Pools für den Level-Up-Screen).
var all_weapons: Array = []
var all_passives: Array = []
## Offene Level-Ups, falls mehrere gleichzeitig ausgelöst werden (z. B. wenn ein
## Gem mit großem Wert mehrere Stufen auf einmal füllt). Ohne Queue würde der
## zweite open()-Aufruf die Auswahl des ersten überschreiben.
var _pending_level_ups := 0

## Hauptboss (M2c-3): spawnt bei Minute 10 (Spawning stoppt -> Boss-Slot).
var _boss: LeshyBoss = null
var _boss_spawned := false


func _ready() -> void:
	# Kamera auf die Arena begrenzen (statt GDScript-Clamping).
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(ARENA_SIZE.x)
	camera.limit_bottom = int(ARENA_SIZE.y)

	# Pools vorwärmen. Zuerst eventuelle Reste eines vorherigen Runs freigeben –
	# beim Szenen-Neustart wird die alte Szene erst verzögert freigegeben, ihre
	# _exit_tree-Aufräumung kann also nach dieser _ready() laufen.
	EnemyPoolManager.release_all_pools()
	EnemyPoolManager.register_pool(POOL_ENEMIES, ENEMY_SCENE, EnemyPoolManager.STRESS_TEST_CAP)
	EnemyPoolManager.attach_pool_to(POOL_ENEMIES, enemy_container)
	EnemyPoolManager.register_pool(POOL_GEMS, GEM_SCENE, 150)
	EnemyPoolManager.attach_pool_to(POOL_GEMS, gem_container)
	EnemyPoolManager.register_pool(POOL_RANGED, RANGED_ENEMY_SCENE, 30)
	EnemyPoolManager.attach_pool_to(POOL_RANGED, enemy_container)
	EnemyPoolManager.register_pool(POOL_FLYERS, FLYER_ENEMY_SCENE, 30)
	EnemyPoolManager.attach_pool_to(POOL_FLYERS, enemy_container)
	EnemyPoolManager.register_pool(POOL_PROJECTILES, ENEMY_PROJECTILE_SCENE, 80)
	EnemyPoolManager.attach_pool_to(POOL_PROJECTILES, _projectile_container)

	# Arena-Größe als Meta an den Spieler (für Positions-Clamp).
	player.set_meta("arena_size", ARENA_SIZE)
	# Run-Stats als Meta (für Upgrades, die Waffe/Regen betreffen).
	player.set_meta("run_stats", {"damage_mult": 1.0, "cooldown_mult": 1.0, "hp_regen": 0.0})

	# Waffen-Daten-Pools aufbauen (für Level-Up-Optionen) und Startwaffe setzen.
	all_weapons = [AXE_DATA, SICKLE_DATA, THUNDER_DATA]
	all_passives = [LESHY_DATA, PERUN_DATA]
	_give_starting_weapon()

	# Verkabelung.
	player.died.connect(_on_player_died)
	player.level_up_ready.connect(_on_level_up_ready)
	level_up_screen.card_chosen.connect(_on_upgrade_chosen)
	death_screen.restart_requested.connect(_restart)

	# SpawnDirector: Region laden und Kurven zurücksetzen.
	SpawnDirector.set_region(REGION_SCENE)
	SpawnDirector.reset()

	# Start: Spieler in die Arena-Mitte.
	player.global_position = ARENA_SIZE / 2.0
	death_screen.hide()

	# Atmosphäre initialisieren (Diablo-1-Anmutung: Nacht + warmer Lichtkegel).
	# Heller als im ersten Pass, damit Gegner-Silhouetten lesbar bleiben.
	atmosphere.color = Color(0.42, 0.44, 0.52, 1)
	_fit_fullscreen_sprite(vignette_shade)
	_fit_fullscreen_sprite(fog)
	_update_hud()


func _process(delta: float) -> void:
	if not running:
		return

	run_time += delta
	# Fraktionale Run-Minute für die Balancing-Kurven (Minute 1 beginnt bei 1).
	run_minute = 1.0 + run_time / 60.0
	player.regen_tick(delta)

	# Atmosphäre: Lagerfeuer-Flackern auf dem Spieler-Licht,
	# Fireflies folgen der Kamera (Emissionszone um den Spieler zentrieren).
	# Nebel driftet langsam über die Karte (Fake-Wolken, reine Sprite-Bewegung).
	player_light.energy = 1.55 + sin(run_time * 7.3) * 0.08 + sin(run_time * 13.7) * 0.05
	fireflies.position = player.global_position
	fog.position = player.global_position + Vector2(sin(run_time * 0.11) * 260.0, cos(run_time * 0.07) * 180.0)

	# Waffen-Multiplikatoren aus den Run-Stats auf ALLE aktiven Waffen übernehmen.
	var stats: Dictionary = player.get_meta("run_stats")
	for entry in inventory.weapons:
		var w: WeaponBase = entry.node
		w.damage_mult = stats["damage_mult"]
		w.cooldown_mult = stats["cooldown_mult"]
		# Krit-Chance aus dem Perun-Amulett (Passiv).
		w.crit_chance_pct = inventory.passive_total(&"crit_chance")

	# Spawn-Loop via SpawnDirector (Balancing-Formeln, .tres-gesteuert).
	# Akkumulator-Spawning: fraktionale Rate → ganze Gegner pro Tick.
	var to_spawn := SpawnDirector.tick_spawning(delta, run_minute, _count_active_enemies())
	for i in to_spawn:
		_spawn_enemy(SpawnDirector.pick_enemy_type(run_minute), false)
	# Elite-Spawns ab Minute 5 (Balancing §6, ×10 HP).
	if SpawnDirector.tick_elite(delta, run_minute):
		_spawn_enemy(_pick_elite_type(), true)

	# Boss-Slot: Ab Minute 10 stoppt das reguläre Spawnen (Balancing §3.4) –
	# jetzt kommt der Hauptboss. Genau einmal pro Run.
	if not _boss_spawned and run_minute >= 10.0:
		_spawn_boss()

	# FPS-Anzeige alle halbe Sekunde aktualisieren (reicht für Greybox).
	if Engine.get_process_frames() % 30 == 0:
		fps_label.text = "FPS: %d" % Engine.get_frames_per_second()

	# Boszbalken (M2c-3): anzeigen, solange Leshy lebt.
	if _boss != null and is_instance_valid(_boss):
		boss_bar.visible = true
		boss_bar.value = _boss.hp_ratio()

	_update_hud()


## Baut das Uniform-Grid der Gegner pro Physik-Tick neu auf. Jeder Gegner
## bekommt seine Zelle und einen Verweis auf das Grid (für die Separation).
func _physics_process(_delta: float) -> void:
	_enemy_grid.clear()
	for enemy in enemy_container.get_children():
		# Nur echte Gegner (TestEnemy) – fremde Nodes im Container (z. B. der
		# Terrain-Hazard des Leshy) haben kein grid_cell-Feld.
		if not enemy is TestEnemy or not enemy.visible:
			continue
		var cell := Vector2i(
			int(enemy.global_position.x / _ENEMY_GRID_CELL),
			int(enemy.global_position.y / _ENEMY_GRID_CELL)
		)
		enemy.grid_cell = cell
		if not enemy.has_meta("enemy_grid"):
			enemy.set_meta("enemy_grid", _enemy_grid)
		if not _enemy_grid.has(cell):
			_enemy_grid[cell] = []
		_enemy_grid[cell].append(enemy)


func _unhandled_input(_event: InputEvent) -> void:
	# Der Neustart nach dem Tod läuft über den DeathScreen (PROCESS_MODE_ALWAYS),
	# weil dieser Knoten bei pausiertem Baum keine Eingaben mehr bekommt.
	pass


## Spawnt einen Gegner aus den EnemyData-Werten (datengetrieben, Balancing §2).
## Skalierung: Basis × Region-Multiplikator × Zeit-Multiplikator (Balancing §5).
## Elites bekommen ×10 HP (Balancing §6: Elite-TTK / Trash-TTK ≈ 10).
func _spawn_enemy(data: EnemyData, elite: bool) -> void:
	# Harte Obergrenze respektieren (Balancing §1).
	if data == null or EnemyPoolManager.count_active(POOL_ENEMIES) >= EnemyPoolManager.HARD_ENEMY_CAP:
		return
	# Fernkämpfer (Role.RANGED) kommen in den eigenen RangedEnemy-Pool
	# und hängen im EnemyContainer, damit Separation/Grid weiterlaufen.
	var is_ranged := data.role == EnemyData.Role.RANGED
	var is_flyer := data.role == EnemyData.Role.FLYER
	var pool_id: StringName = POOL_FLYERS if is_flyer else (POOL_RANGED if is_ranged else POOL_ENEMIES)
	if EnemyPoolManager.count_active(pool_id) >= EnemyPoolManager.HARD_ENEMY_CAP:
		return
	var enemy: Area2D = EnemyPoolManager.get_instance(pool_id)
	if enemy == null:
		return
	var hp_mult := SpawnDirector.hp_multiplier_for(run_minute) * SpawnDirector.region.hp_multiplier
	var dmg_mult := SpawnDirector.damage_multiplier_for(run_minute) * SpawnDirector.region.damage_multiplier
	enemy.setup_from_data(data, hp_mult, dmg_mult, elite)
	enemy.global_position = _random_offscreen_position()
	enemy.target = player
	enemy.on_died = _on_enemy_died
	if is_ranged or is_flyer:
		# Fernkampf-Callable injizieren: Projektil aus dem Pool + skalierte
		# Schadenswerte (der Gegner übergibt nur Position/Richtung/Tempo).
		enemy.fire_projectile = _fire_enemy_projectile


## Feindliches Projektil abfeuern (Callable-Signatur des RangedEnemy).
func _fire_enemy_projectile(pos: Vector2, dir: Vector2, speed: float, damage: float) -> void:
	var proj: Area2D = EnemyPoolManager.get_instance(POOL_PROJECTILES)
	if proj == null:
		return  # Pool erschöpft → Schuss fällt aus (kein Crash)
	proj.call("launch", pos, dir, speed, damage)


	proj.call("launch", pos, dir, speed, damage)


## Spawnt den Hauptboss (M2c-3): Minute 10, nach dem Spawn-Stopp (Boss-Slot).
## Boss-HP ist fix (Balancing §6): KEIN Zeit-Multiplikator, Region-Multiplikator
## ist in den Basiswerten bereits eingerechnet -> Multiplikatoren 1.0.
func _spawn_boss() -> void:
	_boss_spawned = true
	var boss: LeshyBoss = BOSS_SCENE.instantiate()
	enemy_container.add_child(boss)
	boss.setup_from_data(BOSS_DATA, 1.0, 1.0, false)
	boss.global_position = _random_offscreen_position()
	boss.target = player
	boss.on_died = _on_boss_died
	_boss = boss


## Boss-Sieg: Run erfolgreich beendet (Meilenstein-2-Kriterium: Boss-Sieg
## ODER -Niederlage nach komplettem 12-Minuten-Run).
func _on_boss_died(boss: LeshyBoss) -> void:
	kills += 1
	running = false
	death_screen.show_victory(_format_time(run_time), kills, player.level)
	get_tree().paused = true


## Zählt aktive Gegner (für den SpawnDirector-Deckel).
func _count_active_enemies() -> int:
	# Deckel zählt ALLE aktiven Gegner (Balancing §3.2: Gesamtzahl,
	# nicht nur Bodentruppen).
	return (EnemyPoolManager.count_active(POOL_ENEMIES)
		+ EnemyPoolManager.count_active(POOL_RANGED)
		+ EnemyPoolManager.count_active(POOL_FLYERS))


## Elite-Typ: aus dem Regions-Mix der Flieger/Eliten-Kandidat (Balancing §3.3,
## Region 1 Minute 5: „Erste Elite (Aitvaras-Gruppe)").
func _pick_elite_type() -> EnemyData:
	if SpawnDirector.region == null:
		return null
	for entry in SpawnDirector.region.enemy_spawn_table:
		if entry.is_elite and entry.from_minute <= run_minute:
			return entry.enemy
	# Fallback: der Typ mit dem höchsten Basis-HP im Mix.
	var best: EnemyData = null
	for entry in SpawnDirector.region.enemy_spawn_table:
		if best == null or entry.enemy.base_hp > best.base_hp:
			best = entry.enemy
	return best


func _random_offscreen_position() -> Vector2:
	# Off-Screen-Ring um den Spieler (Technisches Setup §2), geclamped auf die Arena.
	var angle := randf() * TAU
	var radius := 700.0 + randf() * 300.0
	var pos: Vector2 = player.global_position + Vector2(cos(angle), sin(angle)) * radius
	return pos.clamp(Vector2(32, 32), ARENA_SIZE - Vector2(32, 32))


func _on_enemy_died(enemy: TestEnemy) -> void:
	kills += 1
	var gem := EnemyPoolManager.get_instance(POOL_GEMS)
	if gem != null:
		gem.global_position = enemy.global_position
		gem.value = enemy.xp_value


func _on_level_up_ready() -> void:
	_pending_level_ups += 1
	# Screen nur öffnen, wenn nicht schon einer offen ist (sonst überschreibt
	# der zweite Aufruf die gerade sichtbare Auswahl).
	if not level_up_screen.visible:
		_show_next_level_up()


func _show_next_level_up() -> void:
	if _pending_level_ups <= 0 or not running:
		return
	_pending_level_ups -= 1
	# Level-Up-Optionen dynamisch aus dem Run-Inventar aufbauen (M2b).
	var options := inventory.build_upgrade_options(all_weapons, all_passives)
	if options.is_empty():
		# Nichts mehr aufzuwerten – Heilung als Fallback (Genre-üblich).
		player.heal(30.0)
		return
	options.shuffle()
	level_up_screen.open(options.slice(0, 3))


func _on_upgrade_chosen(id: StringName) -> void:
	_apply_upgrade_choice(id)
	# Nächstes aufgeschobenes Level-Up direkt nachreichen.
	_show_next_level_up()


## Wendet die gewählte Level-Up-Option an (M2b: Waffen/Passivs/Evolution).
func _apply_upgrade_choice(id: StringName) -> void:
	match id:
		&"uralteichen_axt":
			_evolve_axe()
		_:
			_apply_inventory_upgrade(id)


func _apply_inventory_upgrade(id: StringName) -> void:
	# Bereits im Inventar → nur Level steigern (keine Dublette anlegen!).
	if not inventory.weapon_by_id(id).is_empty():
		if inventory.upgrade_weapon(id):
			var entry := inventory.weapon_by_id(id)
			(entry.node as WeaponBase).level_up()
		return
	if inventory.passive_level(id) > 0:
		if inventory.upgrade_passive(id):
			_apply_passive_stats()
		return
	# Nicht im Inventar → neue Waffe oder neues Passiv hinzufügen.
	var weapon_data := _weapon_data_by_id(id)
	if weapon_data != null and inventory.weapons.size() < RunInventory.MAX_WEAPON_SLOTS:
		_spawn_weapon(weapon_data)
		return
	var passive_data := _passive_data_by_id(id)
	if passive_data != null and inventory.passives.size() < RunInventory.MAX_PASSIVE_SLOTS:
		inventory.add_passive(passive_data)
		_apply_passive_stats()


## Passiv-Stat-Boni auf den Spieler anwenden (Waffen-Dokument §3).
func _apply_passive_stats() -> void:
	var hp_pct := inventory.passive_total(&"max_hp_pct")
	if hp_pct > 0.0:
		player.set_max_hp(100.0 * (1.0 + hp_pct / 100.0))
	var speed_pct := inventory.passive_total(&"move_speed_pct")
	if speed_pct > 0.0:
		player.set_speed_multiplier(1.0 + speed_pct / 100.0)


## Startwaffe (Axt) geben und beim Spieler anheften.
func _give_starting_weapon() -> void:
	_spawn_weapon(AXE_DATA)


## Instanziiert eine Waffenszene aus ihrer WeaponData und verknüpft sie.
func _spawn_weapon(data: WeaponData) -> void:
	var scene: PackedScene = _weapon_scene_for(data)
	var node: Node2D = scene.instantiate()
	weapon_container.add_child(node)
	node.setup(data)
	node.owner_node = player
	node.enemy_container = enemy_container
	inventory.add_weapon(data, node)


func _weapon_scene_for(data: WeaponData) -> PackedScene:
	match data.weapon_type:
		WeaponData.Type.BLEED_MELEE:
			return SICKLE_SCENE
		WeaponData.Type.CHAIN:
			return THUNDER_SCENE
		_:
			return AXE_SCENE


func _weapon_data_by_id(id: StringName) -> WeaponData:
	for data: WeaponData in all_weapons:
		if data.id == id:
			return data
	return null


func _passive_data_by_id(id: StringName) -> PassiveData:
	for data: PassiveData in all_passives:
		if data.id == id:
			return data
	return null


## Evolution der Axt: Axt Lv. 8 + Leshy-Rinde Lv. 5 → Uralteichen-Axt.
func _evolve_axe() -> void:
	var axe_entry := inventory.weapon_by_id(&"axe_holzfaenger")
	if axe_entry.is_empty():
		return
	inventory.evolve(AXE_DATA, URALTEICHEN_DATA)
	(axe_entry.node as WeaponBase).apply_evolution(URALTEICHEN_DATA)


func _on_player_died() -> void:
	running = false
	death_screen.show_results(_format_time(run_time), kills, player.level)
	# Baum pausieren: friert Gegner, Spawns, Waffe und Timer ein.
	get_tree().paused = true


func _restart() -> void:
	get_tree().paused = false
	if get_tree().current_scene != null:
		get_tree().reload_current_scene()
	else:
		# Fallback, falls die Szene nicht als current_scene läuft.
		get_tree().change_scene_to_file(scene_file_path)


## Pool-Instanzen beim Szenenende freigeben. Ohne das würden die Pools beim
## Neustart ein zweites Mal registriert (und verwaiste Instanzen zurückbleiben).
func _exit_tree() -> void:
	EnemyPoolManager.release_all_pools()


func _update_hud() -> void:
	time_label.text = _format_time(run_time)
	level_label.text = "Lv. %d" % player.level
	kills_label.text = "Kills: %d" % kills
	xp_bar.max_value = player.xp_to_next
	xp_bar.value = player.xp_current


## Skaliert ein Fullscreen-Sprite auf die aktuelle Viewport-Größe.
## Sprite2D kennt keine Anker – deshalb zur Laufzeit einpassen (einmalig in
## _ready, Stretch-Mode „expand" ändert die Fläche nur bei Rotation/Resize).
func _fit_fullscreen_sprite(sprite: Sprite2D) -> void:
	var view_size := get_viewport_rect().size
	var tex_size := Vector2(sprite.texture.get_width(), sprite.texture.get_height())
	if tex_size.x > 0.0 and tex_size.y > 0.0:
		sprite.scale = Vector2(view_size.x / tex_size.x, view_size.y / tex_size.y)


func _format_time(seconds: float) -> String:
	var m := int(seconds) / 60
	var s := int(seconds) % 60
	return "%02d:%02d" % [m, s]
