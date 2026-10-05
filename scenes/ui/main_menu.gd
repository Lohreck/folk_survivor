extends Control
## Meta-Hauptmenü (M3c/M3d, UI-UX §4): Gold-Anzeige, Talentbaum mit
## Kauf-Buttons, Charakter-Übersicht und Charakterauswahl. Flache
## Hierarchie: von jeder Unteransicht aus ein Tap zurück (UI-UX §4).
##
## Der UI-Baum wird per Code aufgebaut (die Szene hält nur die Wurzel) –
## die Menüstruktur bleibt damit an einer Stelle lesbar und headless
## überprüfbar. Navigationsbaum (UI-UX §4, Regionsauswahl seit M4a):
##   Hauptmenü → Spielen → Charakterauswahl → Regionsauswahl → Run
##   Hauptmenü → Talentbaum / Charaktere

const RUN_SCENE_PATH := "res://scenes/main.tscn"
## Alle Regionen in Freischalt-Reihenfolge (Regionen-Dok §6, M4a) –
## Namens- und Datenquelle der Regionsauswahl; freigeschaltet werden sie
## über MetaProgress (lineare Reihenfolge nach Hauptboss-Sieg).
const REGION_LIST: Array = [
	preload("res://resources/regions/region_dammerwald.tres"),
	preload("res://resources/regions/region_sumpfmoor.tres"),
	preload("res://resources/regions/region_dorf.tres"),
	preload("res://resources/regions/region_nav_reich.tres"),
]
const VIEW_BG := Color(0.043, 0.055, 0.047)
const ACCENT := Color(0.85, 0.72, 0.38)

var _gold_label: Label
var _home_view: Control
var _talent_view: Control
var _chars_view: Control
var _select_view: Control
var _region_view: Control
var _views: Array[Control] = []
## Talent-Zeilen: StringName -> {level: Label, cost: Label, buy: Button}
var _talent_rows := {}
## Charakter-Übersicht: StringName -> Label (Status/Bedingung)
var _char_status := {}
## Charakterauswahl: StringName -> {status: Label, button: Button}
var _select_rows := {}
## Regionsauswahl: Regionsnummer -> {status: Label, button: Button,
## region: RegionData}
var _region_rows := {}


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_background()
	_home_view = _make_view("HomeView")
	_build_home_content(_home_view)
	_talent_view = _make_view("TalentView")
	_build_talent_content(_talent_view)
	_chars_view = _make_view("CharsView")
	_build_chars_content(_chars_view)
	_select_view = _make_view("SelectView")
	_build_select_content(_select_view)
	_region_view = _make_view("RegionView")
	_build_region_content(_region_view)
	_views = [_home_view, _talent_view, _chars_view, _select_view, _region_view]
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


## Ein Ansichts-Block: zentrierter VBox-„Block" fester Spaltenbreite.
## Playtest 2026-10-02 („Shop unübersichtlich, vieles verschoben"):
##   – Breite 640 → 720: Platz für die Talent-Beschreibung mit Umbruch,
##     damit die Lv.-/Kosten-/Kaufen-Spalten zeilenübergreifend fluchten.
##   – separation 16 → 10 und kompaktere Spacer: die 8-Zeilen-Ansichten
##     (Charaktere/Auswahl) passen sicher in den 720-px-Höhenviewport,
##     statt oben/unten beschnitten zu werden.
func _make_view(view_name: String) -> Control:
	var view := CenterContainer.new()
	view.name = view_name
	view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var box := VBoxContainer.new()
	box.name = "Box"
	box.add_theme_constant_override("separation", 10)
	box.custom_minimum_size = Vector2(720, 0)
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
	box.add_child(_make_button("Spielen",
		func() -> void: _show_view(_select_view), "BtnPlay"))
	box.add_child(_make_button("Talentbaum",
		func() -> void: _show_view(_talent_view), "BtnTalents"))
	box.add_child(_make_button("Charaktere",
		func() -> void: _show_view(_chars_view), "BtnChars"))


func _build_talent_content(view: Control) -> void:
	var box: VBoxContainer = view.get_node("Box")
	box.add_child(_make_heading("Talentbaum"))
	for id: Variant in MetaProgress.talent_ids():
		box.add_child(_make_talent_row(StringName(str(id))))
	box.add_child(_make_spacer(4))
	box.add_child(_make_button("Zurück",
		func() -> void: _show_view(_home_view), "BtnBack"))


func _make_talent_row(id: StringName) -> Control:
	var row := HBoxContainer.new()
	row.name = "Row_" + String(id)
	row.add_theme_constant_override("separation", 24)
	var info := VBoxContainer.new()
	info.name = "Info"
	# Playtest 2026-10-02: Info füllt die Restbreite der Zeile – Level-,
	# Kosten- und Kauf-Spalte stehen damit in allen Zeilen identisch
	# (vorher sprangen sie je nach Beschreibungslänge).
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var name_label := Label.new()
	name_label.text = MetaProgress.talent_name(id)
	name_label.add_theme_font_size_override("font_size", 24)
	info.add_child(name_label)
	var desc := Label.new()
	desc.text = MetaProgress.talent_description(id)
	desc.add_theme_font_size_override("font_size", 15)
	desc.add_theme_color_override("font_color", Color(0.7, 0.7, 0.68))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
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
	# Einheitliche Button-Höhe, auch wenn die Info-Zeile durch umbrechende
	# Beschreibungen höher ausfällt (Playtest 2026-10-02).
	buy.size_flags_vertical = Control.SIZE_SHRINK_CENTER
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
		info.name = "Info"
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
	box.add_child(_make_spacer(4))
	box.add_child(_make_button("Zurück",
		func() -> void: _show_view(_home_view), "BtnBack"))


func _build_select_content(view: Control) -> void:
	var box: VBoxContainer = view.get_node("Box")
	box.add_child(_make_heading("Charakterauswahl"))
	for def: Dictionary in CharacterDefs.CHARACTERS:
		box.add_child(_make_select_row(def))
	box.add_child(_make_spacer(4))
	# Playtest 2026-10-02: Hauptaktion + Zurück nebeneinander (volle Breite)
	# – zwei volle Button-Zeilen drückten die Ansicht über den 720-px-Viewport
	# und „Zurück" wurde unten abgeschnitten.
	# M4a: Die Hauptaktion führt über die Regionsauswahl (UI-UX §4:
	# Charakterauswahl → Regionsauswahl → Run startet).
	var bottom := HBoxContainer.new()
	bottom.name = "BottomRow"
	bottom.add_theme_constant_override("separation", 16)
	var start := _make_button("Weiter →",
		func() -> void: _show_view(_region_view), "BtnStart")
	start.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.add_child(start)
	var back := _make_button("Zurück",
		func() -> void: _show_view(_home_view), "BtnBack")
	back.custom_minimum_size = Vector2(220, 58)
	bottom.add_child(back)
	box.add_child(bottom)


func _make_select_row(def: Dictionary) -> Control:
	var id: StringName = def["id"]
	var row := HBoxContainer.new()
	row.name = "Row_" + String(id)
	row.add_theme_constant_override("separation", 20)
	var info := VBoxContainer.new()
	info.name = "Info"
	var name_label := Label.new()
	name_label.text = str(def["name"])
	name_label.add_theme_font_size_override("font_size", 22)
	info.add_child(name_label)
	var stats := Label.new()
	stats.name = "StatsLabel"
	stats.text = CharacterDefs.stats_line(id)
	stats.add_theme_font_size_override("font_size", 14)
	stats.add_theme_color_override("font_color", Color(0.65, 0.65, 0.62))
	info.add_child(stats)
	row.add_child(info)
	var status := Label.new()
	status.name = "StatusLabel"
	status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	status.add_theme_font_size_override("font_size", 17)
	row.add_child(status)
	var action := Button.new()
	action.name = "ActionBtn"
	action.custom_minimum_size = Vector2(170, 52)
	action.pressed.connect(_on_char_action.bind(id))
	row.add_child(action)
	_select_rows[id] = {"status": status, "button": action}
	return row


func _build_region_content(view: Control) -> void:
	var box: VBoxContainer = view.get_node("Box")
	box.add_child(_make_heading("Regionsauswahl"))
	for def: Variant in REGION_LIST:
		box.add_child(_make_region_row(def as RegionData))
	box.add_child(_make_spacer(4))
	# Wie die Charakterauswahl: Hauptaktion + Zurück nebeneinander.
	var bottom := HBoxContainer.new()
	bottom.name = "BottomRow"
	bottom.add_theme_constant_override("separation", 16)
	var start := _make_button("Run starten →", _on_start_run, "BtnStart")
	start.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.add_child(start)
	var back := _make_button("Zurück",
		func() -> void: _show_view(_select_view), "BtnBack")
	back.custom_minimum_size = Vector2(220, 58)
	bottom.add_child(back)
	box.add_child(bottom)


func _make_region_row(region: RegionData) -> Control:
	var row := HBoxContainer.new()
	row.name = "Region_" + String(region.id)
	row.add_theme_constant_override("separation", 20)
	var name_label := Label.new()
	name_label.text = region.display_name
	name_label.add_theme_font_size_override("font_size", 22)
	row.add_child(name_label)
	var status := Label.new()
	status.name = "StatusLabel"
	status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	status.add_theme_font_size_override("font_size", 17)
	row.add_child(status)
	var action := Button.new()
	action.name = "ActionBtn"
	action.custom_minimum_size = Vector2(170, 52)
	action.pressed.connect(_on_region_select.bind(region.region_number))
	row.add_child(action)
	_region_rows[region.region_number] = {
		"status": status, "button": action, "region": region}
	return row


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
	elif view == _select_view:
		_refresh_select()
	elif view == _region_view:
		_refresh_regions()


func _refresh_gold() -> void:
	_gold_label.text = "Gold: %d" % MetaProgress.gold


func _on_gold_changed(total: int) -> void:
	_gold_label.text = "Gold: %d" % total
	# Kaufbarkeit hängt am Gold – Talent- und Auswahlfzeilen neu bewerten.
	_refresh_talents()
	_refresh_select()


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
		var def := CharacterDefs.get_def(char_id)
		if not MetaProgress.is_character_unlocked(char_id):
			status.text = str(def.get("hint", ""))
			status.add_theme_color_override("font_color", Color(0.78, 0.6, 0.55))
		elif not bool(def.get("playable", false)):
			# Freigespielt, aber Kit kommt erst mit M4 („alle 8 final“).
			status.text = "Kit folgt (M4)"
			status.add_theme_color_override("font_color", Color(0.6, 0.66, 0.78))
		else:
			status.text = "Frei"
			status.add_theme_color_override("font_color", Color(0.55, 0.8, 0.5))


func _refresh_select() -> void:
	# Auswahl validieren (z. B. nach Save-Wechsel): sonst Start-Charakter.
	if not MetaProgress.select_character(MetaProgress.selected_character):
		MetaProgress.select_character(&"holzaeller")
	for id: Variant in _select_rows:
		var char_id := StringName(str(id))
		var def := CharacterDefs.get_def(char_id)
		var row: Dictionary = _select_rows[char_id]
		var status := row["status"] as Label
		var button := row["button"] as Button
		var playable := bool(def.get("playable", false))
		var unlocked := MetaProgress.is_character_unlocked(char_id)
		var selected := MetaProgress.selected_character == char_id
		if not playable:
			# Kit folgt mit M4 – Vorschau mit Freischalt-Bedingung (UI-UX §4).
			status.text = str(def.get("hint", ""))
			status.add_theme_color_override("font_color",
				Color(0.55, 0.58, 0.62) if unlocked else Color(0.78, 0.6, 0.55))
			button.text = "Folgt M4"
			button.disabled = true
		elif selected:
			status.text = "✓ gewählt"
			status.add_theme_color_override("font_color", Color(0.55, 0.8, 0.5))
			button.text = "Gewählt"
			button.disabled = true
		elif unlocked:
			status.text = "Bereit"
			status.add_theme_color_override("font_color", Color(0.55, 0.8, 0.5))
			button.text = "Wählen"
			button.disabled = false
		else:
			var cost := int(def.get("unlock_gold", 0))
			status.text = str(def.get("hint", ""))
			status.add_theme_color_override("font_color", Color(0.78, 0.6, 0.55))
			if cost > 0:
				button.text = "%d Gold" % cost
				button.disabled = MetaProgress.gold < cost
			else:
				button.text = str(def.get("hint", ""))
				button.disabled = true


func _refresh_regions() -> void:
	# Auswahl validieren (z. B. nach Save-Wechsel): sonst Region 1.
	if not MetaProgress.select_region(MetaProgress.selected_region):
		MetaProgress.select_region(1)
	for number: Variant in _region_rows:
		var region_number := int(number)
		var row: Dictionary = _region_rows[region_number]
		var status := row["status"] as Label
		var button := row["button"] as Button
		var selected := MetaProgress.selected_region == region_number
		var unlocked := MetaProgress.is_region_unlocked(region_number)
		if selected:
			status.text = "✓ gewählt"
			status.add_theme_color_override("font_color", Color(0.55, 0.8, 0.5))
			button.text = "Gewählt"
			button.disabled = true
		elif unlocked:
			status.text = "Bereit"
			status.add_theme_color_override("font_color", Color(0.55, 0.8, 0.5))
			button.text = "Wählen"
			button.disabled = false
		else:
			# Lineare Freischaltung (Regionen-Dok §1): die Vorgängerregion
			# muss zuerst gewonnen werden – Bedingung sichtbar als Text.
			var previous := REGION_LIST[region_number - 2] as RegionData
			status.text = "Nach Sieg in %s" % previous.display_name
			status.add_theme_color_override("font_color", Color(0.78, 0.6, 0.55))
			button.text = "Gesperrt"
			button.disabled = true


## Auswertbare Fortschritts-Bedingungen (Charaktere-Dokument §1): beim
## ersten Erfüllen wird die Freischaltung persistiert. Gold-Käufe laufen
## über _on_char_action; Region-Bedingungen der späteren Kits (Waisenkind
## & Co.) kommen mit den Region-Inhalten (M4b/c/g).
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


# ---------------------------------------------------------------------------
# Aktionen
# ---------------------------------------------------------------------------

func _on_talent_buy(id: StringName) -> void:
	MetaProgress.buy_talent(id)
	# Auch bei Fehlschlag (zu wenig Gold) neu bewerten – buy_talent emittet
	# bei Erfolg selbst gold_changed, hier der explizite Fehlschlag-Fall.
	_refresh_talents()


## Wählen bzw. Gold-Freischalten in der Charakterauswahl (Wirtschaft §4).
## spend_gold() prüft den Bestand – erst bei Erfolg wird freigeschaltet,
## gewählt und der Kauf über gold_changed im Menü sichtbar.
func _on_char_action(id: StringName) -> void:
	var def := CharacterDefs.get_def(id)
	if not bool(def.get("playable", false)):
		return  # Button ist disabled – rein defensive.
	if MetaProgress.is_character_unlocked(id):
		MetaProgress.select_character(id)
	else:
		var cost := int(def.get("unlock_gold", 0))
		if cost > 0 and MetaProgress.spend_gold(cost):
			MetaProgress.unlock_character(id)
			MetaProgress.select_character(id)
	_refresh_select()
	_refresh_chars()


func _on_start_run() -> void:
	var err := get_tree().change_scene_to_file(RUN_SCENE_PATH)
	if err != OK:
		push_warning("MainMenu: Run-Szene nicht ladbar (Fehler %d)" % err)


## Region wählen (Regionen-Dok §1, M4a): nur freigeschaltete Regionen –
## die Buttons gesperrter Zeilen sind disabled, select_region validiert
## zusätzlich.
func _on_region_select(region_number: int) -> void:
	MetaProgress.select_region(region_number)
	_refresh_regions()
