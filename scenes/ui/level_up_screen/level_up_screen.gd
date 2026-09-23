extends CanvasLayer
class_name LevelUpScreen
## Level-Up-Auswahl (UI/UX §3): Spiel pausiert, 3 Karten, großes Tap-Target.
##
## Der Run öffnet den Screen per open(cards) und reagiert auf card_chosen.
## Layout: Landscape, 3 Karten nebeneinander, Reroll bewusst weggelassen (M1).
## Controller-Support (M2c-Feedback): erste Karte wird angefokust – D-Pad/Stick
## navigiert, ui_accept (A/Enter) wählt.

signal card_chosen(id: StringName)

const _CARD_SCENE := preload("res://scenes/ui/level_up_screen/upgrade_card.tscn")

@onready var _cards_box: HBoxContainer = $Center/VBox/CardsBox


func _ready() -> void:
	visible = false
	# Level-Up-Screen pausiert den Rest des Spiels vollständig.
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = false # Sicherstellen, dass wir nicht pausiert starten.


## cards: Array von Dictionaries {id, title, desc, icon_color}
func open(cards: Array) -> void:
	for child in _cards_box.get_children():
		child.queue_free()
	for card_data in cards:
		var card := _CARD_SCENE.instantiate()
		_cards_box.add_child(card)
		card.setup(card_data)
		card.card_pressed.connect(_on_card_pressed)
	visible = true
	get_tree().paused = true
	# Controller: erste Karte anfokussen – erst nach dem Sichtbarwerden,
	# deshalb deferred.
	_focus_first_card.call_deferred()


func _focus_first_card() -> void:
	if _cards_box.get_child_count() == 0:
		return
	var first := _cards_box.get_child(0)
	if first is Control:
		first.grab_focus.call_deferred()


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


func _on_card_pressed(id: StringName) -> void:
	# Idempotent: Fokus-Pfad und _unhandled_input-Fallback dürfen nicht beide
	# greifen und das Upgrade doppelt anwenden.
	if not visible:
		return
	visible = false
	get_tree().paused = false
	card_chosen.emit(id)
