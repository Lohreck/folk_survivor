extends CanvasLayer
class_name LevelUpScreen
## Level-Up-Auswahl (UI/UX §3): Spiel pausiert, 3 Karten, großes Tap-Target.
##
## Der Run öffnet den Screen per open(cards) und reagiert auf card_chosen.
## Layout: Landscape, 3 Karten nebeneinander, Reroll bewusst weggelassen (M1).

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


func _on_card_pressed(id: StringName) -> void:
	visible = false
	get_tree().paused = false
	card_chosen.emit(id)
