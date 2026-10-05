extends Area2D
class_name Chest
## Truhe (M4f, Wirtschaft §2.2/§3): seltener Gold-Drop, Erwartung ~3 pro
## 12-Minuten-Run (Versuch alle 60 s, Basis-Chance 25 %). Der Talentknoten
## „Glücksfinder“ erhöht die Spawn-Chance um +5 Prozentpunkte pro Stufe.
##
## Bewusst KEIN Magnet wie beim XP-Gem: Die Truhe steht still, der Spieler
## geht bewusst hin (Sammel-Radius 44 px). Ohne Kollisionsform – die
## Distanzprüfung in _physics_process ist deterministisch (gleiches Muster
## wie das Gem, nur ohne Anziehung) und stört weder MagnetArea noch
## Projektile. Nicht gepoolt (nur ~3 pro Run), gerootet von main.gd.

## Ab dieser Distanz zum Spieler gilt die Truhe als eingesammelt.
const PICKUP_DISTANCE := 44.0

## Auszahlung (RegionData.chest_gold_min/max) und Sammelziel.
var value := 20
var target: Node2D
## main.gd hängt hier die Run-Gold-Gutschrift an (Wirtschaft §2.1).
var on_collected: Callable = Callable()

var _collected := false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 0
	monitoring = false
	monitorable = false
	queue_redraw()


func _physics_process(_delta: float) -> void:
	if _collected or target == null or not is_instance_valid(target):
		return
	if target.global_position.distance_to(global_position) <= PICKUP_DISTANCE:
		_collect()


func _collect() -> void:
	# Vor dem Freigeben sperren, damit kein Doppel-Sammeln möglich ist.
	_collected = true
	set_physics_process(false)
	var world := get_parent()
	var gold_pos := global_position
	if on_collected.is_valid():
		on_collected.call(value)
	_spawn_float_text(world, gold_pos)
	queue_free()


## Kurzes „+N Gold“-Label, das nach oben wegblendet – das einzige In-Run-
## Feedback. Das Gold selbst wird wie Kill-Gold erst beim Run-Ende
## kreditiert (main.gd._on_chest_collected), der Label-Text nennt den
## Rohtwert der Truhe.
func _spawn_float_text(world: Node, gold_pos: Vector2) -> void:
	var label := Label.new()
	label.text = "+%d Gold" % value
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	world.add_child(label)
	label.global_position = gold_pos + Vector2(-26.0, -46.0)
	var tween := label.create_tween()
	tween.tween_property(label, "position:y", label.position.y - 44.0, 0.9)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.9)
	tween.tween_callback(label.queue_free)


## Greybox-Truhe ohne Asset: Korpus, Deckel, goldenes Band + Schloss,
## plus Aufmerksamkeits-Umriss, damit sie im Gedränge auffällt.
func _draw() -> void:
	draw_rect(Rect2(-18, -6, 36, 20), Color(0.45, 0.28, 0.15))
	draw_rect(Rect2(-18, -14, 36, 10), Color(0.58, 0.38, 0.2))
	draw_rect(Rect2(-18, -4, 36, 4), Color(0.78, 0.62, 0.25))
	draw_rect(Rect2(-4, -5, 8, 9), Color(0.95, 0.8, 0.35))
	draw_rect(Rect2(-20, -16, 40, 32), Color(1.0, 0.9, 0.4, 0.55), false, 2.0)
