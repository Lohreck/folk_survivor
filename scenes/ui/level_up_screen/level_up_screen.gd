extends CanvasLayer
class_name LevelUpScreen
## Level-Up-Auswahl (UI/UX §3): Spiel pausiert, 3 Karten, großes Tap-Target.
##
## Der Run öffnet den Screen per open(cards, rerolls) und reagiert auf
## card_chosen. Layout: Landscape, 3 Karten nebeneinander; der Reroll (M3e,
## Playtest 2026-10-02) ist ein breiter Button UNTER den Karten – nur
## sichtbar, solange Rerolls übrig sind, und zeigt die Restanzahl
## (UI/UX §3). reroll_requested bittet den Run um neue Karten – der Screen
## bleibt dabei offen und pausiert.
## Controller-Support (M2c-Feedback): erste Karte wird angefokust – D-Pad/Stick
## navigiert, ui_accept (A/Enter) wählt; der Reroll-Button ist als letztes
## Element erreichbar und wird in _input mitbedient (Joypad-Doppel-Auslösung).

signal card_chosen(id: StringName)
signal reroll_requested

const _CARD_SCENE := preload("res://scenes/ui/level_up_screen/upgrade_card.tscn")

@onready var _cards_box: HBoxContainer = $Center/VBox/CardsBox
## Reroll-Button unter den Karten (UI/UX §3) – per Code gebaut, in _ready
## als letztes Kind der VBox eingehängt.
@onready var _reroll_button: Button = _make_reroll_button()


func _ready() -> void:
	visible = false
	# Level-Up-Screen pausiert den Rest des Spiels vollständig.
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = false # Sicherstellen, dass wir nicht pausiert starten.
	get_node("Center/VBox").add_child(_reroll_button)
	_reroll_button.visible = false


## cards: Array von Dictionaries {id, title, desc, icon_color}
## rerolls: verbleibende Rerolls – 0 heißt Reroll-Button ausgeblendet (UI/UX §3).
func open(cards: Array, rerolls: int = 0) -> void:
	_rebuild(cards, rerolls)
	visible = true
	get_tree().paused = true
	# Controller: erste Karte anfokussen – erst nach dem Sichtbarwerden,
	# deshalb deferred.
	_focus_first_card.call_deferred()


## Reroll (M3e): die 3 Angebotskarten neu ziehen – Screen bleibt offen und
## pausiert. Evolutionen/Fusionen werden vom Run aus dem aktuellen Inventar
## neu berechnet und sind in den neuen Karten entsprechend enthalten.
func refill(cards: Array, rerolls: int) -> void:
	_rebuild(cards, rerolls)
	_focus_first_card.call_deferred()


func _rebuild(cards: Array, rerolls: int) -> void:
	for child in _cards_box.get_children():
		child.queue_free()
	for card_data in cards:
		var card := _CARD_SCENE.instantiate()
		_cards_box.add_child(card)
		card.setup(card_data)
		card.card_pressed.connect(_on_card_pressed)
	# Reroll (Playtest 2026-10-02): breiter Button unter den Karten statt
	# eigener Karte – belegt keinen Karten-Slot, ist gut erreichbar und
	# zeigt den Reststand (UI/UX §3).
	_reroll_button.visible = rerolls > 0
	_reroll_button.text = "Reroll: Neue Karten ziehen (Rest: %d)" % rerolls


func _focus_first_card() -> void:
	# Guard: Der Deferred-Aufruf kann nach der Kartenwahl (visible=false) oder
	# einem Szenenwechsel ankommen – dann darf hier kein Fokus mehr queue'd
	# werden, sonst landet grab_focus später ohne Baum und meldet
	# "!is_inside_tree". Der Fokus-Keeper in _process fängt Nachzügler ab.
	if not visible or not is_inside_tree():
		return
	if _cards_box.get_child_count() == 0:
		return
	var first := _cards_box.get_child(0)
	# Direkt (nicht erneut deferred): wir laufen bereits am Frame-Ende, und
	# die Sichtbarkeit ist hier geprüft – ein zweiter Deferred-Schritt könnte
	# erst nach Screen-Schließen/Szenenwechsel feuern.
	if first is Control and first.is_inside_tree():
		first.grab_focus()


## Fokus-Keeper: Beim Neuladen (2. Level-Up im Run) gibt Viewport den Fokus
## der alten, gerade freigegebenen Karten manchmal erst NACH unserem grab_focus()
## frei – der Screen bliebe dann fokuslos und der Controller unfähig. Solange
## sichtbar und fokuslos, wird die erste Karte (Nachfolger) erneut angefokust;
## bei aktiver Navigation greift das nie (Fokus dann ≠ null).
func _process(_delta: float) -> void:
	if not visible or _cards_box.get_child_count() == 0:
		return
	if get_viewport().gui_get_focus_owner() == null:
		var first := _cards_box.get_child(0)
		if first is Control:
			first.grab_focus()


## Auswahl per Controller/Keyboard (M2c-Feedback): laeuft bewusst in _input,
## also VOR der GUI – dann erreicht A/Enter die fokussierte Karte garantiert,
## auch wenn die Viewport-GUI den Joypad-Druck sonst schluckt. Akzeptiert
## ui_accept (A/Enter/Space) sowie den rohen A-Knopf. Der Guard in
## _on_card_pressed macht eine Doppel-Ausloesung (GUI + dieser Pfad) ungeschaedlich.
func _input(event: InputEvent) -> void:
	if not visible:
		return
	var accept := event.is_action_pressed("ui_accept")
	if not accept and event is InputEventJoypadButton:
		accept = event.pressed and (event as InputEventJoypadButton).button_index == JOY_BUTTON_A
	if not accept:
		return
	var focus := get_viewport().gui_get_focus_owner()
	if focus != null and focus.has_signal("card_pressed"):
		focus.emit_signal("card_pressed", focus.get("_id"))
	elif focus == _reroll_button and _reroll_button.visible:
		# Reroll-Button: selbes Problem wie bei Karten (Joypad-Doppel-Auslösung
		# über _input + GUI) – hier abfangen und die GUI sperren, damit ein
		# Druck genau einmal feuert.
		_on_reroll_pressed()
		get_viewport().set_input_as_handled()


func _on_card_pressed(id: StringName) -> void:
	# Idempotent: Fokus-Pfad und _unhandled_input-Fallback dürfen nicht beide
	# greifen und das Upgrade doppelt anwenden.
	if not visible:
		return
	visible = false
	get_tree().paused = false
	card_chosen.emit(id)


## Einziger Auslöser-Pfad des Reroll-Buttons (GUI-Tap bzw. Joypad über _input):
## schließt nichts – der Run zieht neue Karten und ruft refill().
func _on_reroll_pressed() -> void:
	if not visible:
		return
	reroll_requested.emit()


## Reroll-Button (Playtest 2026-10-02): „länglicher Knopf" über volle Breite
## unter den drei Karten, Blau-Ton als Akzent der Reroll-Aktion (UI/UX §3).
func _make_reroll_button() -> Button:
	var btn := Button.new()
	btn.name = "RerollButton"
	btn.custom_minimum_size = Vector2(0, 56)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.add_theme_font_size_override("font_size", 20)
	btn.add_theme_color_override("font_color", Color(0.8, 0.88, 1.0))
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.13, 0.2, 0.33, 0.95)
	normal.set_corner_radius_all(10)
	normal.set_border_width_all(1)
	normal.border_color = Color(0.55, 0.72, 0.92)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.18, 0.27, 0.44, 0.95)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color(0.09, 0.14, 0.24, 0.95)
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.pressed.connect(_on_reroll_pressed)
	return btn
