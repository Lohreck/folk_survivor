extends Button
## Eine Upgrade-Karte im Level-Up-Screen (UI/UX §3).
##
## Gesamte Karte ist Tap-Fläche (kein kleiner Button). Zeigt Icon-Platzhalter,
## Titel und eine einzeilige Kurzbeschreibung.

signal card_pressed(id: StringName)

var _id: StringName

@onready var _icon: ColorRect = $VBox/Icon
@onready var _title: Label = $VBox/Title
@onready var _desc: Label = $VBox/Desc


func setup(data: Dictionary) -> void:
	_id = data["id"]
	_title.text = data["title"]
	_desc.text = data["desc"]
	_icon.color = data["icon_color"]
	# Evolution: goldener Rahmen als visuelles Signal (Waffen-Dokument §1).
	if data.get("is_evolution", false):
		add_theme_color_override("font_color", Color(1.0, 0.85, 0.25))
		_title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.25))


func _pressed() -> void:
	card_pressed.emit(_id)

