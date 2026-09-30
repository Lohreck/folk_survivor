extends Control
## Meta-Hauptmenü (M3c, UI-UX §4): Gold-Anzeige, Talentbaum mit Kauf-Buttons
## und Charakter-Übersicht. Flache Hierarchie: von jeder Unteransicht aus ein
## Tap zurück (UI-UX §4: Meta-Menü darf keine Spielzeit fressen).
##
## Der UI-Baum wird per Code aufgebaut (die Szene hält nur die Wurzel) –
## die Menüstruktur bleibt damit an einer Stelle lesbar und headless
## überprüfbar. „Spielen“ startet direkt den Run; die Charakterauswahl
## dazwischen kommt mit M3d.

const RUN_SCENE_PATH := "res://scenes/main.tscn"
const VIEW_BG := Color(0.043, 0.055, 0.047)
const ACCENT := Color(0.85, 0.72, 0.38)

var _gold_label: Label
var _home_view: Control
var _talent_view: Control
var _chars_view: Control
var _views: Array[Control] = []
## Talent-Zeilen: StringName -> {level: Label, cost: Label, buy: Button}
var _talent_rows := {}
## Charakter-Statuslabels: StringName -> Label
var _char_status := {}


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_background()
	_home_view = _make_view("HomeView")
	_build_home_content(_home_view)
	_talent_view = _make_view("TalentView")
	_build_talent_content(_talent_view)
	_chars_view = _make_view("CharsView")
	_build_chars_content(_chars_view)
	_views = [_home_view, _talent_view, _chars_view]
	for view: Control in _views:
		add_child(view)
	MetaProgress.gold_changed.connect(_on_gold_changed)
	_refresh_gold()
	_show_view(_home_view)


# ---------------------------------------------------------------------------
# Aufbau
# ---------------------------------------------------------------------------

func _build_background() -> void:
	var bg := ColorRect.new()
	bg.name = "Background"
	bg.color = VIEW_BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)


func _make_view(view_name: String) -> Control:
	var view := CenterContainer.new()
	view.name = view_name
	view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var box := VBoxContainer.new()
	box.name = "Box"
	box.add_theme_constant_override("separation", 16)
	box.custom_minimum_size = Vector2(640, 0)
	view.add_child(box)
	return view


func _build_home_content(view: Control) -> void:
	var box: VBoxContainer = view.get_node("Box")
	var title := Label.new()
	title.name = "TitleLabel"
	title.text = "Nav' – Slawische Horde"
	title.add_theme_font_size_override("font_size", 44)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	_gold_label = Label.new()
	_gold_label.name = "GoldLabel"
	_gold_label.add_theme_font_size_override("font_size", 26)
	_gold_label.add_theme_color_override("font_color", ACCENT)
	_gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_gold_label)
	box.add_child(_make_spacer(16))
	box.add_child(_make_button("Spielen", _on_play, "BtnPlay"))
	box.add_child(_make_button("Talentbaum",
		func() -> void: _show_view(_talent_view), "BtnTalents"))
	box.add_child(_make_button("Charaktere",
		func() -> void: _show_view(_chars_view), "BtnChars"))


func _build_talent_content(view: Control) -> void:
	var box: VBoxContainer = view.get_node("Box")
	box.add_child(_make_heading("Talentbaum"))
	for id: Variant in MetaProgress.talent_ids():
		box.add_child(_make_talent_row(StringName(str(id))))
	box.add_child(_make_spacer(8))
	box.add_child(_make_button("Zurück",
		func() -> void: _show_view(_home_view), "BtnBack"))


func _make_talent_row(id: StringName) -> Control:
	var row := HBoxContainer.new()
	row.name = "Row_" + String(id)
	row.add_theme_constant_override("separation", 24)
	var info := VBoxContainer.new()
	var name_label := Label.new()
	name_label.text = MetaProgress.talent_name(id)
	name_label.add_theme_font_size_override("font_size", 24)
	info.add_child(name_label)
	var desc := Label.new()
	desc.text = MetaProgress.talent_description(id)
	desc.add_theme_font_size_override("font_size", 15)
	desc.add_theme_color_override("font_color", Color(0.7, 0.7, 0.68))
	info.add_child(desc)
	row.add_child(info)
	var level := Label.new()
	level.name = "LevelLabel"
	level.custom_minimum_size = Vector2(120, 0)
	level.add_theme_font_size_override("font_size", 18)
	row.add_child(level)
	var cost := Label.new()
	cost.name = "CostLabel"
	cost.custom_minimum_size = Vector2(120, 0)
	cost.add_theme_font_size_override("font_size", 18)
	row.add_child(cost)
	var buy := Button.new()
	buy.name = "BuyButton"
	buy.text = "Kaufen"
	buy.custom_minimum_size = Vector2(140, 52)
	buy.pressed.connect(_on_talent_buy.bind(id))
	row.add_child(buy)
	_talent_rows[id] = {"level": level, "cost": cost, "buy": buy}
	return row


func _build_chars_content(view: Control) -> void:
	var box: VBoxContainer = view.get_node("Box")
	box.add_child(_make_heading("Charaktere"))
	for def: Dictionary in CharacterDefs.CHARACTERS:
		var id: StringName = def["id"]
		var row := HBoxContainer.new()
		row.name = "Char_" + String(id)
		row.add_theme_constant_override("separation", 24)
		var info := VBoxContainer.new()
		var name_label := Label.new()
		name_label.text = str(def["name"])
		name_label.add_theme_font_size_override("font_size", 22)
		info.add_child(name_label)
		var arch := Label.new()
		arch.text = str(def["archetype"])
		arch.add_theme_font_size_override("font_size", 14)
		arch.add_theme_color_override("font_color", Color(0.65, 0.65, 0.62))
		info.add_child(arch)
		row.add_child(info)
		var status := Label.new()
		status.name = "StatusLabel"
		status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		status.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		status.add_theme_font_size_override("font_size", 17)
		row.add_child(status)
		_char_status[id] = status
		box.add_child(row)
	box.add_child(_make_spacer(8))
	box.add_child(_make_button("Zurück",
		func() -> void: _show_view(_home_view), "BtnBack"))


func _make_heading(text: String) -> Label:
	var heading := Label.new()
	heading.text = text
	heading.add_theme_font_size_override("font_size", 32)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return heading


func _make_button(text: String, on_pressed: Callable, node_name: String) -> Button:
	var btn := Button.new()
	btn.name = node_name
	btn.text = text
	btn.custom_minimum_size = Vector2(340, 58)
	btn.add_theme_font_size_override("font_size", 22)
	btn.pressed.connect(on_pressed)
	return btn


func _make_spacer(height: float) -> Control:
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, height)
	return spacer


# ---------------------------------------------------------------------------
# Navigation & Refresh
# ---------------------------------------------------------------------------

func _show_view(view: Control) -> void:
	for v: Control in _views:
		v.visible = v == view
	if view == _talent_view:
		_refresh_talents()
	elif view == _chars_view:
		_refresh_chars()


func _refresh_gold() -> void:
	_gold_label.text = "Gold: %d" % MetaProgress.gold


func _on_gold_changed(total: int) -> void:
	_gold_label.text = "Gold: %d" % total
	# Kaufbarkeit der Talente hängt am Gold – Zeilen neu bewerten.
	_refresh_talents()


func _refresh_talents() -> void:
	for id: Variant in _talent_rows:
		var talent_id := StringName(str(id))
		var row: Dictionary = _talent_rows[talent_id]
		var level := MetaProgress.talent_level(talent_id)
		var cost := MetaProgress.talent_cost(talent_id)
		(row["level"] as Label).text = "Lv. %d/%d" % [
			level, MetaProgress.talent_max_level(talent_id)]
		var buy := row["buy"] as Button
		if cost <= 0:
			(row["cost"] as Label).text = "Max"
			buy.text = "Maximal"
			buy.disabled = true
		else:
			(row["cost"] as Label).text = "%d Gold" % cost
			buy.text = "Kaufen"
			buy.disabled = MetaProgress.gold < cost


func _refresh_chars() -> void:
	for id: Variant in _char_status:
		var char_id := StringName(str(id))
		_evaluate_progress_unlock(char_id)
		var status: Label = _char_status[char_id]
		if MetaProgress.is_character_unlocked(char_id):
			status.text = "Frei"
			status.add_theme_color_override("font_color", Color(0.55, 0.8, 0.5))
		else:
			status.text = str(CharacterDefs.get_def(char_id).get("hint", ""))
			status.add_theme_color_override("font_color", Color(0.78, 0.6, 0.55))


## Auswertbare Fortschritts-Bedingungen (Charaktere-Dokument §1): beim
## ersten Erfüllen wird die Freischaltung persistiert. Gold-Käufe (Kräuter-
## frau, Jäger) und spätere Regionen kommen mit der Charakterauswahl (M3d).
func _evaluate_progress_unlock(id: StringName) -> void:
	var met := false
	match id:
		&"wanderpriesterin":
			met = MetaProgress.has_defeated_boss(&"leshy")
		&"kraeuterfrau":
			met = MetaProgress.has_defeated_boss(&"rusalka")
		_:
			met = false
	if met:
		MetaProgress.unlock_character(id)


func _on_talent_buy(id: StringName) -> void:
	MetaProgress.buy_talent(id)
	# Auch bei Fehlschlag (zu wenig Gold) neu bewerten – buy_talent emittet
	# bei Erfolg selbst gold_changed, hier der explizite Fehlschlag-Fall.
	_refresh_talents()


func _on_play() -> void:
	var err := get_tree().change_scene_to_file(RUN_SCENE_PATH)
	if err != OK:
		push_warning("MainMenu: Run-Szene nicht ladbar (Fehler %d)" % err)
