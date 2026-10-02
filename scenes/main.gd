extends Node2D
## Meilenstein 2b – Waffen, Passivs, erste Evolution.
##
## Baut auf M2a auf: Ersetzt die M1-Platzhalter-Upgrades durch das echte
## Run-Inventar (Waffen-Slots 5, Passiv-Slots 5, Waffen-Dokument §1).
## Waffen: Axt, Sichel, Donnerkeil, Weihwasser-Phiole, Eisernes Hufeisen
## (Lv. 1–8, DPS ×1.30/Lv., Balancing §8).
## Passivs: Leshy-Rinde, Perun-Amulett, Domovoi-Glöckchen, Aitvaras-Feder,
## Rusalka-Träna (Stat-Boni, auch ohne Waffe nutzbar).
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
const PHIOLE_SCENE := preload("res://scenes/weapons/phiole_weapon.tscn")
const HUFEN_SCENE := preload("res://scenes/weapons/hufeisen_weapon.tscn")
const AXE_DATA := preload("res://resources/weapons/axe_holzfaenger.tres")
const SICKLE_DATA := preload("res://resources/weapons/sichel.tres")
const THUNDER_DATA := preload("res://resources/weapons/donnerkeil.tres")
const PHIOLE_DATA := preload("res://resources/weapons/weihwasser_phiole.tres")
const LESHY_DATA := preload("res://resources/weapons/leshy_rinde.tres")
const PERUN_DATA := preload("res://resources/weapons/perun_amulett.tres")
const URALTEICHEN_DATA := preload("res://resources/weapons/uralteichen_axt.tres")
const HUFEN_DATA := preload("res://resources/weapons/eisernes_hufeisen.tres")
const GLOCK_DATA := preload("res://resources/weapons/domovoi_gloeckchen.tres")
const FEDER_DATA := preload("res://resources/weapons/aitvaras_feder.tres")
const TRAENE_DATA := preload("res://resources/weapons/rusalka_traene.tres")
const BOSS_SCENE := preload("res://scenes/enemies/leshy_boss.tscn")
const BOSS_DATA := preload("res://resources/enemies/leshy.tres")
const ARENA_SIZE := Vector2(4096, 4096)
## Aura-Radius des Domovoi-Glöckchens auf Stufe 1 (px) – wächst mit der
## Level-Stufe bis zur Verdopplung auf Stufe 5 (Waffen-Dokument §3).
const AURA_RADIUS_BASE := 96.0

const POOL_ENEMIES: StringName = &"enemies"
const POOL_RANGED: StringName = &"ranged_enemies"
const POOL_FLYERS: StringName = &"flyer_enemies"
## Max. gleichzeitige Fernkämpfer (Domovoi + Aitvaras zusammen).
## Playtest 2026-10-02: „schnell zu viele da" – Cap drosselt die Ansammlung,
## wenn die Fernkämpfer nicht schnell genug sterben (Tuning-Register §5.1).
## Elites sind ausgenommen (Einzel-Spawn mit eigenem Budget).
const RANGED_ACTIVE_CAP := 6
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
@onready var level_up_screen: LevelUpScreen = $LevelUpScreen

var run_time := 0.0
var kills := 0
var running := true
## Fraktionales Run-Gold aus Kill-Werten (EnemyData.gold_value, Wirtschaft §2.1).
## Wird erst beim Run-Ende über das Talent „Glückshändler“ skaliert, gerundet
## und in MetaProgress kreditiert (dort Autosave je Mutation).
var run_gold := 0.0

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
## Passiv-Aura (Domovoi-Glöckchen): Radius/Verlangsamung aus dem Inventar,
## pro Frame auf schwache Gegner im Radius angewendet (Waffen-Dok §3).
var _aura_slow_pct := 0.0
var _aura_radius := 0.0
var _aura_visual: Polygon2D
## Offene Level-Ups, falls mehrere gleichzeitig ausgelöst werden (z. B. wenn ein
## Gem mit großem Wert mehrere Stufen auf einmal füllt). Ohne Queue würde der
## zweite open()-Aufruf die Auswahl des ersten überschreiben.
var _pending_level_ups := 0
## Verbleibende Karten-Rerolls im laufenden Run: Basis 3 + „Wahrsagerei“
## (UI/UX §3, Wirtschaft §3). Wird beim Run-Start gesetzt, nicht gespeichert.
var rerolls_left := 0
## Pause-UI (M3e): Button oben rechts + Overlay, per Code gebaut (wie Menü).
var _pause_layer: CanvasLayer
var _pause_overlay: Control
var _pause_button: Button

## Hauptboss (M2c-3): spawnt bei Minute 10 (Spawning stoppt -> Boss-Slot).
var _boss: LeshyBoss = null
var _boss_spawned := false
## Spawn-Zeitpunkt für die Boss-TTK (Telemetrie §4: boss_defeated „Zeit bis Kill“).
var _boss_spawn_time := 0.0

## Telemetrie (§4): ob für das aktuell offene Level-Up gerollt wurde
## (level_up-Event „Reroll ja/nein“). Wird beim Öffnen zurückgesetzt.
var _level_up_rerolled := false
## Nächte Sekunde für den 1-Hz-Gegner-Sample (enemy_count_sample, §4).
var _next_enemy_sample := 1.0


func _ready() -> void:
	# Kamera auf die Arena begrenzen (statt GDScript-Clamping).
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(ARENA_SIZE.x)
	camera.limit_bottom = int(ARENA_SIZE.y)

	# Nahtlose Waldboden-Kachel als Hintergrund (Atmosphäre, Diablo-Look).
	($World/Background as TextureRect).texture = preload("res://assets/sprites/ground.png")

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
	# Charakter-Kit anwenden (CharacterDefs: HP, Tempo, Passiv) – der
	# Spieler-Ready lief vor diesem Aufruf, deshalb explizit konfigurieren.
	var char_def := CharacterDefs.get_def(MetaProgress.selected_character)
	player.configure_character(
		float(char_def.get("max_hp", 140.0)),
		float(char_def.get("speed_mult", 0.8)),
		StringName(char_def.get("passive", &"zaehe_haut")))
	# Run-Stats als Meta (für Upgrades, die Waffe/Regen betreffen).
	player.set_meta("run_stats", {"damage_mult": 1.0, "cooldown_mult": 1.0, "hp_regen": 0.0})

	# Sichtbare Aura des Domovoi-Glöckchens: weicher Ring um den Spieler,
	# als erstes Child gezeichnet (hinter der Figur), per Code wie die
	# Pause-UI. Radius/Polygon kommen beim ersten Passiv-Level-Update.
	_aura_visual = Polygon2D.new()
	_aura_visual.color = Color(0.55, 0.78, 1.0, 0.10)
	_aura_visual.visible = false
	player.add_child(_aura_visual)
	player.move_child(_aura_visual, 0)

	# Talent „Ahnensegen“ (Wirtschaft §3): +5 Start-HP pro Stufe.
	var hp_bonus: float = MetaProgress.start_hp_bonus()
	if hp_bonus > 0.0:
		player.set_max_hp(player.max_hp + hp_bonus)
	# Talent „Wahrsagerei“ (UI/UX §3): Reroll-Budget für diesen Run.
	rerolls_left = MetaProgress.start_rerolls()

	# Waffen-Daten-Pools aufbauen (für Level-Up-Optionen) und Startwaffe setzen.
	all_weapons = [AXE_DATA, SICKLE_DATA, THUNDER_DATA, PHIOLE_DATA, HUFEN_DATA]
	all_passives = [LESHY_DATA, PERUN_DATA, GLOCK_DATA, FEDER_DATA, TRAENE_DATA]
	_give_starting_weapon()

	# Verkabelung.
	player.died.connect(_on_player_died)
	player.level_up_ready.connect(_on_level_up_ready)
	level_up_screen.card_chosen.connect(_on_upgrade_chosen)
	level_up_screen.reroll_requested.connect(_on_reroll_requested)
	death_screen.restart_requested.connect(_restart)
	death_screen.menu_requested.connect(_goto_menu)
	_build_pause_ui()

	# SpawnDirector: Region laden und Kurven zurücksetzen.
	SpawnDirector.set_region(REGION_SCENE)
	SpawnDirector.reset()

	# Start: Spieler in die Arena-Mitte.
	player.global_position = ARENA_SIZE / 2.0
	death_screen.hide()

	# Atmosphäre initialisieren (Diablo-1-Anmutung: Nacht + warmer Lichtkegel).
	# Nach Playtest-Feedback (M2c) heller: Platzhalter-Sprites müssen lesbar
	# sein – final wird das via Contrast/Palette gelöst, nicht per Nacht.
	atmosphere.color = Color(0.72, 0.73, 0.78, 1)
	_fit_fullscreen_sprite(vignette_shade)
	_fit_fullscreen_sprite(fog, true)
	_update_hud()

	# Run-Start (Telemetrie §4): Region, Charakter, Startwaffe, Reroll-Budget.
	Telemetry.track(&"run_start", {
		"region": REGION_SCENE.id,
		"character": MetaProgress.selected_character,
		"weapon": StringName(char_def.get("start_weapon", &"axe_holzfaenger")),
		"rerolls": rerolls_left,
	})


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
	player_light.energy = 1.9 + sin(run_time * 7.3) * 0.08 + sin(run_time * 13.7) * 0.05
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
		# Flächenschaden (Aitvaras-Feder) und Blutungs-Lifesteal (Rusalka-
		# Träna) – beide kommen als Passiv-Werte auf alle Waffen an.
		w.area_damage_pct = inventory.passive_total(&"area_damage_pct")
		w.lifesteal_pct = inventory.passive_total(&"lifesteal_pct")

	# Domovoi-Glöckchen: schwache Gegner (Schwarm-Rolle, keine Elites) im
	# Radius um den Spieler pro Frame verlangsamen (Waffen-Dokument §3).
	# Der Effekt verfällt im Gegner nach einem Frame, wenn hier nichts
	# gesetzt wird – kein Gegenaufruf nötig.
	if _aura_slow_pct > 0.0 and _aura_radius > 0.0:
		var aura_radius_sq := _aura_radius * _aura_radius
		var player_pos := player.global_position
		for enemy in enemy_container.get_children():
			if not enemy.visible or not enemy.has_method("apply_aura_slow"):
				continue
			if enemy.get("is_elite") == true:
				continue
			if enemy.get("enemy_role") != EnemyData.Role.SWARM:
				continue
			if enemy.global_position.distance_squared_to(player_pos) <= aura_radius_sq:
				enemy.apply_aura_slow(_aura_slow_pct)

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

	# Telemetrie (§4): aktive Gegner 1×/s sampeln (Performance + Spawn-Tuning).
	if run_time >= _next_enemy_sample:
		Telemetry.track(&"enemy_count_sample", {
			"n": _count_active_enemies(),
			"minute": run_minute,
		})
		_next_enemy_sample += 1.0

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
	# Fernkämpfer-Cap (Playtest 2026-10-02): überschüssige Fernkämpfer-Spawns
	# entfallen – das Wellen-Budget wird bewusst nicht umverteilt, die Welle
	# spawnt damit insgesamt weniger, solange das Cap steckt.
	if not elite and (is_ranged or is_flyer):
		var ranged_active := EnemyPoolManager.count_active(POOL_RANGED) \
			+ EnemyPoolManager.count_active(POOL_FLYERS)
		if ranged_active >= RANGED_ACTIVE_CAP:
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
		# Schadenswerte (der Gegner übergibt Position/Richtung/Tempo plus
		# seine Quell-Kennung für die Telemetrie).
		enemy.fire_projectile = _fire_enemy_projectile


## Feindliches Projektil abfeuern (Callable-Signatur des RangedEnemy).
func _fire_enemy_projectile(pos: Vector2, dir: Vector2, speed: float, damage: float, source: StringName) -> void:
	var proj: Area2D = EnemyPoolManager.get_instance(POOL_PROJECTILES)
	if proj == null:
		return  # Pool erschöpft → Schuss fällt aus (kein Crash)
	proj.call("launch", pos, dir, speed, damage, source)


## Spawnt den Hauptboss (M2c-3): Minute 10, nach dem Spawn-Stopp (Boss-Slot).
## Boss-HP ist fix (Balancing §6): KEIN Zeit-Multiplikator, Region-Multiplikator
## ist in den Basiswerten bereits eingerechnet -> Multiplikatoren 1.0.
func _spawn_boss() -> void:
	_boss_spawned = true
	_boss_spawn_time = run_time
	var boss: LeshyBoss = BOSS_SCENE.instantiate()
	enemy_container.add_child(boss)
	boss.setup_from_data(BOSS_DATA, 1.0, 1.0, false)
	boss.global_position = _random_offscreen_position()
	boss.target = player
	boss.on_died = _on_boss_died
	_boss = boss
	Telemetry.track(&"boss_spawn", {"minute": run_minute, "time_s": run_time})


## Boss-Sieg: Run erfolgreich beendet (Meilenstein-2-Kriterium: Boss-Sieg
## ODER -Niederlage nach komplettem 12-Minuten-Run).
func _on_boss_died(boss: LeshyBoss) -> void:
	kills += 1
	running = false
	run_gold += boss.gold_value
	# Telemetrie §4: TTK über die Zeit zwischen boss_spawn und -defeated.
	Telemetry.track(&"boss_defeated", {"ttk_s": run_time - _boss_spawn_time, "minute": run_minute})
	var earned := _credit_run_gold(REGION_SCENE.boss_gold_bonus, &"boss")
	MetaProgress.mark_boss_defeated(&"leshy")
	_track_run_end(&"victory", earned)
	death_screen.show_victory(_format_time(run_time), kills, player.level, earned)
	get_tree().paused = true


## Run-Gold kreditieren (Wirtschaft §2.1): Kills × Gold-Rate-Talent plus
## flacher Bonus (Boss-Sieg §2.2 bzw. Überlebenszeit-Bonus §2.3 bei Tod vor
## Run-Ende). Gibt den gerundeten Gesamtwert für den Run-End-Screen zurück.
## source kennzeichnet die Bonus-Herkunft für das gold_earned-Event (§4).
func _credit_run_gold(flat_bonus: int, source: StringName) -> int:
	var earned := roundi(run_gold * MetaProgress.gold_rate_multiplier()) + flat_bonus
	MetaProgress.add_gold(earned)
	# Run-End-Auszahlung: enthält die mit dem Talent skalierten Kills-Gold
	# (credited_total), deshalb als eigene Quelle markiert – Summen über
	# alle gold_earned-Events nicht blind addieren.
	Telemetry.track(&"gold_earned", {
		"source": source,
		"credited_total": earned,
		"flat_bonus": flat_bonus,
		"kill_gold_raw": run_gold,
	})
	return earned


## Run-Ende protokollieren (Telemetrie §4: Region, Charakter, Dauer,
## Todesminute, Sieg/Niederlage). Die Aufrufer stellen sicher, dass
## `running` bereits false ist – so bleibt jedes Run-Ende eindeutig.
func _track_run_end(outcome: StringName, earned: int) -> void:
	var props := {
		"outcome": String(outcome),
		"duration_s": run_time,
		"kills": kills,
		"level": player.level,
		"region": REGION_SCENE.id,
		"character": MetaProgress.selected_character,
		"gold": earned,
		"gold_raw": run_gold,
	}
	if outcome == &"death":
		props["death_minute"] = run_minute
	Telemetry.track(&"run_end", props)


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
	run_gold += enemy.gold_value
	# Telemetrie §4 (gold_earned, Quelle Kills): fraktionaler Gold-Wert des
	# Gegentyps – Rohsumme steht zusätzlich in run_end (gold_raw).
	Telemetry.track(&"gold_earned", {
		"source": &"kills",
		"amount": enemy.gold_value,
		"enemy": enemy.source_id,
	})
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
	_level_up_rerolled = false
	level_up_screen.open(options.slice(0, 3), rerolls_left)


func _on_upgrade_chosen(id: StringName) -> void:
	# Telemetrie §4 (level_up): gewählte Karte + ob vor der Wahl gerollt wurde.
	Telemetry.track(&"level_up", {
		"card": id,
		"rerolled": _level_up_rerolled,
		"rerolls_left": rerolls_left,
		"minute": run_minute,
		"level": player.level,
	})
	_apply_upgrade_choice(id)
	# Nächstes aufgeschobenes Level-Up direkt nachreichen.
	_show_next_level_up()


## Reroll (M3e, UI/UX §3): Budget abziehen und die 3 Angebotskarten neu
## ziehen – Evolutionen/Fusionen werden dabei aus dem aktuellen Inventar
## neu berechnet. Läuft synchron im Signalpfad, das Tree-Pausieren ist für
## diesen Aufruf also ohne Bedeutung.
func _on_reroll_requested() -> void:
	if rerolls_left <= 0:
		return
	rerolls_left -= 1
	var options := inventory.build_upgrade_options(all_weapons, all_passives)
	if options.is_empty():
		# Kein Pool – die bisherigen Karten behalten (refill würde leeren).
		rerolls_left += 1
		return
	options.shuffle()
	level_up_screen.refill(options.slice(0, 3), rerolls_left)
	_level_up_rerolled = true


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
## Beide Werte rechnen auf der Charakter-Basis (Holzfäller: 140 HP, 0.8×).
func _apply_passive_stats() -> void:
	var hp_pct := inventory.passive_total(&"max_hp_pct")
	if hp_pct > 0.0:
		player.set_max_hp_percent(hp_pct)
	var speed_pct := inventory.passive_total(&"move_speed_pct")
	if speed_pct > 0.0:
		player.set_speed_multiplier(1.0 + speed_pct / 100.0)
	# Domovoi-Glöckchen (Passiv-Aura, Waffen-Dokument §3): Radius wächst
	# über die Level-Stufen bis zur Verdopplung (Lv. 1 → Lv. 5), die
	# Verlangsamung selbst kommt aus dem Stat-Wert.
	var glock_level := inventory.passive_level(&"domovoi_gloeckchen")
	if glock_level > 0:
		_aura_slow_pct = inventory.passive_total(&"aura_slow_pct")
		_aura_radius = AURA_RADIUS_BASE * (1.0 + float(glock_level - 1) / 4.0)
		_aura_visual.polygon = _circle_points(_aura_radius)
		_aura_visual.visible = true
	else:
		_aura_slow_pct = 0.0
		_aura_radius = 0.0
		_aura_visual.visible = false


## Startwaffe des gewählten Charakters (CharacterDefs „start_weapon“)
## geben und beim Spieler anheften. Fallback = Axt (Holzfäller-Defaults).
func _give_starting_weapon() -> void:
	var def := CharacterDefs.get_def(MetaProgress.selected_character)
	var weapon_id := StringName(def.get("start_weapon", &"axe_holzfaenger"))
	var weapon_data := _weapon_data_by_id(weapon_id)
	_spawn_weapon(weapon_data if weapon_data != null else AXE_DATA)


## Instanziiert eine Waffenszene aus ihrer WeaponData und verknüpft sie.
func _spawn_weapon(data: WeaponData) -> void:
	var scene: PackedScene = _weapon_scene_for(data)
	var node: Node2D = scene.instantiate()
	weapon_container.add_child(node)
	node.setup(data)
	node.owner_node = player
	node.enemy_container = enemy_container
	node.fx_container = weapon_container
	inventory.add_weapon(data, node)


func _weapon_scene_for(data: WeaponData) -> PackedScene:
	match data.weapon_type:
		WeaponData.Type.BLEED_MELEE:
			return SICKLE_SCENE
		WeaponData.Type.CHAIN:
			return THUNDER_SCENE
		WeaponData.Type.THROWN_AOE:
			return PHIOLE_SCENE
		WeaponData.Type.THROWN_RETURN:
			return HUFEN_SCENE
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


## Kreis-Polygon für die Aura-Visualisierung (Domovoi-Glöckchen).
func _circle_points(radius: float, segments: int = 24) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in segments:
		points.append(Vector2.RIGHT.rotated(TAU * float(i) / float(segments)) * radius)
	return points


## Evolution der Axt: Axt Lv. 8 + Leshy-Rinde Lv. 5 → Uralteichen-Axt.
func _evolve_axe() -> void:
	var axe_entry := inventory.weapon_by_id(&"axe_holzfaenger")
	if axe_entry.is_empty():
		return
	inventory.evolve(AXE_DATA, URALTEICHEN_DATA)
	(axe_entry.node as WeaponBase).apply_evolution(URALTEICHEN_DATA)
	# Telemetrie §4: Erreichbarkeit der Evolutionen. (double_evolved gibt es
	# erst mit den Doppel-Evolutionen in M4.)
	Telemetry.track(&"weapon_evolved", {
		"weapon": URALTEICHEN_DATA.id,
		"minute": run_minute,
		"level": player.level,
	})


func _on_player_died() -> void:
	running = false
	# Todesursache (Telemetrie §4: One-Shot-Erkennung) – die letzte Quelle
	# samt Trefferstärke gegen die max. HP. Chronologisch VOR run_end.
	Telemetry.track(&"death_cause", {
		"source": player.last_damage_source,
		"amount": player.last_damage_amount,
		"max_hp": player.max_hp,
		"minute": run_minute,
	})
	# Überlebenszeit-Bonus bei Tod vor Run-Ende (Wirtschaft §2.3):
	# (überlebte Minuten / 12) × Voll-Run-Gold-Wert × 0.5.
	var minutes := run_time / 60.0
	var survival := roundi(minutes / 12.0 * float(REGION_SCENE.estimated_full_run_gold) * 0.5)
	var earned := _credit_run_gold(survival, &"survival")
	_track_run_end(&"death", earned)
	death_screen.show_results(_format_time(run_time), kills, player.level, earned)
	# Baum pausieren: friert Gegner, Spawns, Waffe und Timer ein.
	get_tree().paused = true


# ---------------------------------------------------------------------------
# Pause (M3e, UI-UX §4)
# ---------------------------------------------------------------------------

## Button oben rechts (bewusst außerhalb der Daumen-Reichweite, UI-UX §4) plus
## Overlay mit Weiter/Neu/Menü. Alles per Code gebaut – wie das Meta-Menü.
func _build_pause_ui() -> void:
	_pause_layer = CanvasLayer.new()
	_pause_layer.name = "PauseLayer"
	# Über dem HUD (5), aber unter dem LevelUpScreen (20) – während der
	# Kartenwahl liegt die Pause-Kante also unter dem Screen; der Guard in
	# _on_pause_pressed ist zusätzlich die harte Kante.
	_pause_layer.layer = 10
	_pause_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_pause_layer)

	_pause_button = Button.new()
	_pause_button.name = "PauseButton"
	_pause_button.text = "II"
	_pause_button.tooltip_text = "Pause"
	_pause_button.add_theme_font_size_override("font_size", 22)
	_pause_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_pause_button.offset_left = -76
	_pause_button.offset_top = 12
	_pause_button.offset_right = -16
	_pause_button.offset_bottom = 64
	_pause_button.pressed.connect(_on_pause_pressed)
	_pause_layer.add_child(_pause_button)

	_pause_overlay = ColorRect.new()
	_pause_overlay.name = "PauseOverlay"
	_pause_overlay.color = Color(0, 0, 0, 0.62)
	_pause_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_pause_overlay.visible = false
	_pause_layer.add_child(_pause_overlay)

	var center := CenterContainer.new()
	center.name = "Center"
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_pause_overlay.add_child(center)
	var box := VBoxContainer.new()
	box.name = "VBox"
	box.add_theme_constant_override("separation", 16)
	center.add_child(box)
	var heading := Label.new()
	heading.name = "Heading"
	heading.text = "Pause"
	heading.add_theme_font_size_override("font_size", 40)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(heading)
	box.add_child(_make_overlay_button("Weiter", _on_pause_resume, "BtnResume"))
	box.add_child(_make_overlay_button("Neu starten", _restart, "BtnRestart"))
	box.add_child(_make_overlay_button("Zum Menü", _goto_menu, "BtnMenu"))


func _make_overlay_button(text: String, on_pressed: Callable, node_name: String) -> Button:
	var btn := Button.new()
	btn.name = node_name
	btn.text = text
	btn.custom_minimum_size = Vector2(320, 58)
	btn.add_theme_font_size_override("font_size", 22)
	btn.pressed.connect(on_pressed)
	return btn


func _on_pause_pressed() -> void:
	# Kein Pause während Level-Up, Tod oder schon pausiert – der Guard ist die
	# harte Kante, weil PauseLayer (10) unter LevelUpScreen (20) liegt und der
	# Button dort erreichbar bliebe.
	if not running or get_tree().paused or level_up_screen.visible or death_screen.visible:
		return
	get_tree().paused = true
	_pause_button.visible = false
	_pause_overlay.visible = true


func _on_pause_resume() -> void:
	get_tree().paused = false
	_pause_overlay.visible = false
	_pause_button.visible = true


func _restart() -> void:
	# Laufenden Run als Abbruch protokollieren (Telemetrie §4 run_end) –
	# nach Tod/Sieg ist running bereits false, der Guard verhindert Doppel.
	if running:
		_track_run_end(&"abort", 0)
	get_tree().paused = false
	if get_tree().current_scene != null:
		get_tree().reload_current_scene()
	else:
		# Fallback, falls die Szene nicht als current_scene läuft.
		get_tree().change_scene_to_file(scene_file_path)


## Zurück ins Meta-Menü (UI-UX §5: „Zum Menü“). Erst pausieren aufheben,
## sonst läuft der Menü-Baum im pausierten Zustand weiter.
func _goto_menu() -> void:
	# Mittendrin verlassen = Abbruch (running greift auch aus der Pause heraus).
	if running:
		_track_run_end(&"abort", 0)
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")


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


## Skaliert ein Fullscreen-Sprite auf die sichtbare Fläche.
## in_world_layers = true: Sprite lebt in einer follow_viewport-Layer (Nebel)
## und wird vom Kamera-Zoom mitskaliert – dann muss es in WELTkoordinaten
## kleiner sein (sichtbare Weltfläche = Viewport / Zoom).
## Screen-Space-Layer (Vignette) nutzen die volle Viewport-Größe.
func _fit_fullscreen_sprite(sprite: Sprite2D, in_world_layers := false) -> void:
	var view_size := get_viewport_rect().size
	if in_world_layers:
		view_size /= camera.zoom
	var tex_size := Vector2(sprite.texture.get_width(), sprite.texture.get_height())
	if tex_size.x > 0.0 and tex_size.y > 0.0:
		sprite.scale = Vector2(view_size.x / tex_size.x, view_size.y / tex_size.y)


func _format_time(seconds: float) -> String:
	var m := int(seconds) / 60
	var s := int(seconds) % 60
	return "%02d:%02d" % [m, s]
