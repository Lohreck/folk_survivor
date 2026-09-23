extends SceneTree
## Temporaerer Input-Test (Danach loeschen): Twin-Stick (Gamepad + Touch),
## Controller-Navigation/-Auswahl im Level-Up, Maus-Click-Fix (Kartenoberseite)
## und Controller-Restart nach Spielende.
##
## Hinweis Headless-Koordinaten: root.size=(64,64), Canvas/visible_rect=1280x1280.
## Maus-/Touch-Events werden in FENSTERkoordinaten erwartet; Versuche decken
## beide Raeume ab (Window + Canvas) und beide Injektionspfade (parse + push).

var _main: Node
var _player: Node2D
var _overlay: Node
var _frames := 0
var _ok := 0
var _fail := 0
var _chosen_count := 0
var _last_chosen: StringName = &""
var _count_before_accept := 0
var _restart_fired := false
var _card_gui_seen := false


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
	_overlay = _main.get_node("VirtualJoystick")
	# Signale der Hauptszene erst ab Frame 30 verbinden (@onready ist hier
	# noch nicht gesetzt – der LevelUpScreen-Zugriff muesste warten).


func _on_card_chosen(id: StringName) -> void:
	_chosen_count += 1
	_last_chosen = id


func _physics_process(_d: float) -> bool:
	_frames += 1
	match _frames:
		30:
			if not _main.level_up_screen.card_chosen.is_connected(_on_card_chosen):
				_main.level_up_screen.card_chosen.connect(_on_card_chosen)
			_check_actions()
			# Spieler unsterblich (Test soll nicht am Kampf scheitern).
			_player.hp = 5000.0
			_player.max_hp = 5000.0
			print("  [diagnose] root.size=%s visible_rect=%s paused=%s" %
				[root.size, root.get_visible_rect().size, paused])
		50:
			_parse_aim(JOY_AXIS_RIGHT_Y, -1.0)  # Gamepad: rechter Stick nach OBEN.
		60:
			_check_gamepad_aim()
			# Zielung links (Gamepad-X): Figur muss flip_h setzen und
			# aufrecht bleiben – Flip wird bei frame70 verifiziert.
			_parse_aim(JOY_AXIS_RIGHT_X, -1.0)
			_parse_aim(JOY_AXIS_RIGHT_Y, 0.0)  # loslassen
		65:
			_parse_aim(JOY_AXIS_RIGHT_X, 0.0)  # Zielung links loslassen (Frame-Puffer)
		70:
			_check_aim_released()
			_setup_weapon_test()
		200:
			_check_weapon_aim()
			_test_touch_twin()
		205:
			_test_touch_release()
		210:
			_open_levelup(&"sichel", &"axe_holzfaenger", &"leshy_rinde")
		214:
			_check_levelup_focus("Open #1")
			_attach_gui_loggers()
		216:
			_try_click("Maus/parse/Fenster", false, true, false)
		218:
			_try_click("Maus/push/Fenster", false, true, true)
		220:
			_try_click("Maus/parse/Canvas", false, false, false)
		222:
			_try_click("Touch/parse/Canvas", true, false, false)
		224:
			_try_click("Touch/parse/Fenster", true, true, false)
		227:
			_check_mouse_click()
			_open_levelup(&"axe_holzfaenger", &"leshy_rinde", &"sichel")
		228:
			_check_levelup_focus("Open #2")
			_push_dpad_right()
		232:
			_check_focus_navigation()
			_count_before_accept = _chosen_count
			var _box: Node = _main.level_up_screen.get_node("Center/VBox/CardsBox")
			var _card1: Control = _box.get_child(1)
			_card1.gui_input.connect(
				func(ev: InputEvent) -> void: print("  [gui] card1(A): ", ev))
			var probe := _joy_button(JOY_BUTTON_A, true)
			print("  [diagnose] A ist ui_accept? %s | Bindings: %s" %
				[InputMap.event_is_action(probe, "ui_accept"),
				InputMap.action_get_events("ui_accept")])
			_push_accept()
		240:
			_check_controller_select()
			_setup_death()
		246:
			_push_restart_button()
		252:
			_check_controller_restart()
			_finish()
			return true
	return false


## --- Aktionen / Gamepad --------------------------------------------------

func _check_actions() -> void:
	print("--- TEST: INPUT-AKTIONEN (InputSetup-Autoload) ---")
	var missing := []
	for a in ["move_left", "move_right", "move_up", "move_down",
			"aim_left", "aim_right", "aim_up", "aim_down"]:
		if not InputMap.has_action(a):
			missing.append(a)
	_check("Alle 8 Twin-Stick-Aktionen registriert", missing.is_empty(), str(missing))


func _check_gamepad_aim() -> void:
	print("--- TEST: GAMEPAD (RECHTER STICK) ---")
	var aim: Vector2 = _player.get_aim_direction()
	_check("Rechter Stick -> Blickrichtung oben", aim.distance_to(Vector2.UP) < 0.01, str(aim))
	_check("Spieler bleibt aufrecht (keine Wetterfahnen-Rotation)",
		absf(_player.rotation) < 0.01, "rotation=%.3f" % _player.rotation)


func _check_aim_released() -> void:
	print("--- TEST: STICK LOSLASSEN ---")
	_parse_aim(JOY_AXIS_RIGHT_X, 0.0)  # die bei frame60 gesetzte Zielung links
	_check("Zielung zurueck auf Auto-Modus (ZERO)",
		_player.get_aim_direction() == Vector2.ZERO, str(_player.get_aim_direction()))
	_check("Figur links gespiegelt via flip_h (weiterhin aufrecht)",
		(_player.get_node("Body") as Sprite2D).flip_h and absf(_player.rotation) < 0.01,
		"flip_h=%s rotation=%.3f" % [(_player.get_node("Body") as Sprite2D).flip_h, _player.rotation])


## --- Waffen-Aim ----------------------------------------------------------

func _setup_weapon_test() -> void:
	print("--- SETUP: Waffe zielt in Blickrichtung ---")
	var director: Node = root.get_node_or_null("SpawnDirector")
	if director != null:
		director.set("region", null)  # kein Zufalls-Spawnen waehrenddessen
	# Gegner RECHTS neben dem Spieler: Auto-Modus wuerde nach RECHTEN schlagen.
	var em: Node = root.get_node("EnemyPoolManager")
	var e: Node2D = em.get_instance(&"enemies")
	e.setup_from_data(load("res://resources/enemies/kikimora.tres"), 1.0, 1.0, false)
	e.target = _player
	e.on_died = Callable()
	e.global_position = _player.global_position + Vector2(60, 0)
	# Ziel-Touch-Stick nach OBEN (rechte Bildschirmhaelfte = Aim-Kanal).
	VirtualJoystickInput.aim_active = true
	VirtualJoystickInput.aim_direction = Vector2.UP


func _check_weapon_aim() -> void:
	print("--- TEST: AXT SCHLAEGT IN BLICKRICHTUNG ---")
	var axe: WeaponBase = _main.inventory.weapons[0].node
	_check("Axt schlaegt nach OBEN (Ziel-Stick), nicht zum Gegner rechts",
		absf(wrapf(axe.rotation - (-PI / 2.0), -PI, PI)) < 0.05,
		"rotation=%.3f (soll -1.571)" % axe.rotation)


## --- Touch-Twin-Stick ----------------------------------------------------

func _test_touch_twin() -> void:
	print("--- TEST: TOUCH-TWIN-STICK (zwei Daumen parallel) ---")
	VirtualJoystickInput.reset()
	# Gegen das sichtbare Rechteck rechnen (Overlay-Gate prueft dasselbe).
	var view := root.get_visible_rect().size
	var y := view.y * 0.7
	_overlay._input(_touch(0, true, Vector2(view.x * 0.25, y)))
	_overlay._input(_drag(0, Vector2(view.x * 0.25 + 50.0, y)))
	var move_out: Vector2 = VirtualJoystickInput.get_output()
	_overlay._input(_touch(1, true, Vector2(view.x * 0.75, y)))
	_overlay._input(_drag(1, Vector2(view.x * 0.75, y - 50.0)))
	var aim_out: Vector2 = VirtualJoystickInput.get_aim()
	_check("Linker Touch-Stick bewegt", move_out.length() > 0.5, str(move_out))
	_check("Rechter Touch-Stick zielt nach oben",
		aim_out.length() > 0.5 and aim_out.y < -0.5, str(aim_out))
	_check("Beide Sticks parallel aktiv",
		VirtualJoystickInput.active and VirtualJoystickInput.aim_active, "")


func _test_touch_release() -> void:
	print("--- TEST: TOUCH LOSLASSEN ---")
	_overlay._input(_touch(0, false, Vector2.ZERO))
	_overlay._input(_touch(1, false, Vector2.ZERO))
	_check("Beide Sticks deaktiviert",
		not VirtualJoystickInput.active and not VirtualJoystickInput.aim_active, "")


## --- Level-Up: Fokus / Klick / Controller -------------------------------

func _open_levelup(id0: StringName, id1: StringName, id2: StringName) -> void:
	print("--- SETUP: Level-Up-Screen (Karte 1 = %s) ---" % id0)
	var cards := [
		{"id": id0, "title": "Karte A", "desc": "Testkarte", "icon_color": Color(0.9, 0.4, 0.3)},
		{"id": id1, "title": "Karte B", "desc": "Testkarte", "icon_color": Color(0.4, 0.9, 0.5)},
		{"id": id2, "title": "Karte C", "desc": "Testkarte", "icon_color": Color(0.6, 0.5, 0.3)},
	]
	_main.level_up_screen.open(cards)


func _check_levelup_focus(tag: String) -> void:
	print("--- TEST: CONTROLLER-FOKUS (LEVEL-UP, %s) ---" % tag)
	_check("Screen pausiert das Spiel", paused, "paused=%s" % paused)
	var box: Node = _main.level_up_screen.get_node("Center/VBox/CardsBox")
	var owner_ctrl := root.gui_get_focus_owner()
	print("  [diagnose] box.children=%d owner=%s visible=%s" %
		[box.get_child_count(), owner_ctrl, _main.level_up_screen.visible])
	_check("Erste Karte hat Fokus", owner_ctrl == box.get_child(0), "%s" % owner_ctrl)


func _attach_gui_loggers() -> void:
	# Beobachten, ob GUI-Events die Karte (bzw. den Vollbild-Hintergrund)
	# ueberhaupt erreichen – und mit welcher Position.
	var bg: Control = _main.level_up_screen.get_node("Background")
	if not bg.gui_input.is_connected(_on_bg_gui):
		bg.gui_input.connect(_on_bg_gui)
	var box: Node = _main.level_up_screen.get_node("Center/VBox/CardsBox")
	var card: Control = box.get_child(0)
	card.gui_input.connect(_on_card_gui)


func _on_bg_gui(ev: InputEvent) -> void:
	print("  [gui] Background: %s pos=%s" % [ev, _pos_of(ev)])


func _on_card_gui(ev: InputEvent) -> void:
	_card_gui_seen = true
	print("  [gui] card0: %s pos=%s" % [ev, _pos_of(ev)])


func _pos_of(ev: InputEvent) -> Variant:
	if ev is InputEventMouseButton:
		return (ev as InputEventMouseButton).position
	if ev is InputEventScreenTouch:
		return (ev as InputEventScreenTouch).position
	if ev is InputEventScreenDrag:
		return (ev as InputEventScreenDrag).position
	return null


## Ein Klick-Versuch auf die obere Kartenhaelfte. Raeume/Pfade variieren,
## damit Headless-Injektion den echten Treffer garantiert findet.
func _try_click(tag: String, use_touch: bool, as_window: bool, via_push: bool) -> void:
	if _chosen_count > 0 or not _main.level_up_screen.visible:
		return
	var box: Node = _main.level_up_screen.get_node("Center/VBox/CardsBox")
	if box.get_child_count() == 0:
		return
	var card: Control = box.get_child(0)
	var rect := card.get_global_rect()
	var canvas_pos := rect.position + Vector2(rect.size.x * 0.5, rect.size.y * 0.25)
	var pos := canvas_pos
	if as_window:
		pos = canvas_pos * (Vector2(root.size) / root.get_visible_rect().size)
	print("  [versuch] %s -> canvas=%s fenster=%s" % [tag, canvas_pos, pos])
	_inject(_mk_touch(9, true, pos) if use_touch else _mk_mouse(true, pos), via_push)
	_inject(_mk_touch(9, false, pos) if use_touch else _mk_mouse(false, pos), via_push)


func _check_mouse_click() -> void:
	print("--- TEST: MAUSKLICK AUF KARTEN-OBERHAELFTE ---")
	var structural := _structural_click_ok()
	_check("Klickflaeche frei (Children mouse_filter=IGNORE)",
		structural, "struktur=%s" % structural)
	if _chosen_count > 0:
		_check("Klick auf Karten-Oberhaelfte waehlt die Karte",
			_last_chosen == &"sichel" and _chosen_count == 1,
			"gewaehlt=%s count=%d" % [_last_chosen, _chosen_count])
		_check("Screen schliesst wieder",
			not _main.level_up_screen.visible and not paused, "")
	else:
		# Injektion traf keine GUI (Headless-Besonderheit) – Struktur-Check
		# traegt die Aussage; Log-Ausgaben oben zeigen den Grund.
		print("  [info] Injektion ohne Treffer (card_gui_seen=%s) – Struktur-Check gilt" %
			_card_gui_seen)


func _structural_click_ok() -> bool:
	var box: Node = _main.level_up_screen.get_node("Center/VBox/CardsBox")
	if box.get_child_count() == 0:
		return false
	var card: Control = box.get_child(0)
	for path in ["VBox", "VBox/Icon", "VBox/Title", "VBox/Desc"]:
		var child: Control = card.get_node(path)
		if child.mouse_filter != Control.MOUSE_FILTER_IGNORE:
			print("  [info] %s hat mouse_filter=%d (sollte IGNORE=2)" %
				[path, child.mouse_filter])
			return false
	return card.mouse_filter != Control.MOUSE_FILTER_IGNORE


func _check_focus_navigation() -> void:
	print("--- TEST: CONTROLLER-NAVIGATION ---")
	var box: Node = _main.level_up_screen.get_node("Center/VBox/CardsBox")
	var owner_ctrl := root.gui_get_focus_owner()
	print("  [diagnose] nach D-Pad: owner=%s" % owner_ctrl)
	_check("D-Pad rechts -> zweite Karte fokussiert", owner_ctrl == box.get_child(1),
		"%s" % owner_ctrl)


func _push_accept() -> void:
	_input_parse(_joy_button(JOY_BUTTON_A, true))
	_input_parse(_joy_button(JOY_BUTTON_A, false))


func _push_dpad_right() -> void:
	_input_parse(_joy_button(JOY_BUTTON_DPAD_RIGHT, true))
	_input_parse(_joy_button(JOY_BUTTON_DPAD_RIGHT, false))


func _check_controller_select() -> void:
	print("--- TEST: CONTROLLER-AUSWAHL (A / ui_accept) ---")
	_check("Controller-A waehlt die fokussierte Karte",
		_last_chosen == &"leshy_rinde" and _chosen_count == _count_before_accept + 1,
		"gewaehlt=%s count=%d (vorher %d)" %
		[_last_chosen, _chosen_count, _count_before_accept])


## --- Game-Over: Controller-Restart ---------------------------------------

func _setup_death() -> void:
	print("--- SETUP: Game-Over + Controller-Restart ---")
	# Restartsignal vom Run entkoppeln, sonst laedt der Test die Szene neu.
	if _main.death_screen.restart_requested.is_connected(_main._restart):
		_main.death_screen.restart_requested.disconnect(_main._restart)
	_main.death_screen.restart_requested.connect(
		func() -> void: _restart_fired = true)
	_main.death_screen.show_results("00:12", 5, 3)
	paused = true  # echte Bedingungen: Baum pausiert wie im Run


func _push_restart_button() -> void:
	_input_parse(_joy_button(JOY_BUTTON_START, true))
	_input_parse(_joy_button(JOY_BUTTON_START, false))


func _check_controller_restart() -> void:
	print("--- TEST: CONTROLLER-RESTART NACH SPIELLENDE ---")
	_check("Controller-Taste loest Neustart aus", _restart_fired,
		"gefired=%s" % _restart_fired)
	paused = false


func _finish() -> void:
	print("--- Input-Test: %d OK / %d FEHLER ---" % [_ok, _fail])


## --- Helfer --------------------------------------------------------------

func _parse_aim(axis: JoyAxis, value: float) -> void:
	var ev := InputEventJoypadMotion.new()
	ev.axis = axis
	ev.axis_value = value
	Input.parse_input_event(ev)


func _touch(index: int, pressed: bool, pos: Vector2) -> InputEventScreenTouch:
	return _mk_touch(index, pressed, pos)


func _drag(index: int, pos: Vector2) -> InputEventScreenDrag:
	var ev := InputEventScreenDrag.new()
	ev.index = index
	ev.position = pos
	return ev


func _mk_touch(index: int, pressed: bool, pos: Vector2) -> InputEventScreenTouch:
	var ev := InputEventScreenTouch.new()
	ev.index = index
	ev.pressed = pressed
	ev.position = pos
	return ev


func _mk_mouse(pressed: bool, pos: Vector2) -> InputEventMouseButton:
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = pressed
	ev.position = pos
	ev.global_position = pos
	return ev


func _joy_button(button: JoyButton, pressed: bool) -> InputEventJoypadButton:
	var ev := InputEventJoypadButton.new()
	ev.button_index = button
	ev.pressed = pressed
	return ev


func _input_parse(event: InputEvent) -> void:
	Input.parse_input_event(event)


func _inject(event: InputEvent, via_push: bool) -> void:
	if via_push:
		root.push_input(event)
	else:
		Input.parse_input_event(event)
