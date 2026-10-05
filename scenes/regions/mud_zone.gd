extends Area2D
class_name MudZone
## Schlamm-Fläche (M4b, Sumpfmoor): statische Zone, die die SPIELFIGUR beim
## Durchqueren verlangsamt (Regionen-Dok §3: „zwingt zu bewusster Routen-
## wahl“). Gegner bleiben unberührt – die Kollisionsmaske deckt nur das
## Spieler-Layer (1) ab.
##
## Erkennung: area_entered/exited hält einen Flag, pro Frame meldet die
## Zone ihren Wert an player.set_area_slow() (Frame-Verfall im Spieler,
## M4b-A) – verfällt die Zone oder stirbt der Mini-Boss, entfällt der
## Aufruf automatisch.

## Verlangsamung in % beim Durchqueren (Startwert 30, Balancing-Hebel §5).
var slow_pct := 30.0
## Seed der Pfützen-Form – pro Zone unterschiedlich (vor add_child setzen).
var shape_seed := 4711

const RADIUS := 110.0
## Unregelmässiger Rand (Pfütze statt Kreis) – Form statt nur Farbe als
## Erkennungsmerkmal (Barrierefreiheit §3.2).
const _SEGMENTS := 36

var _player: Area2D
var _player_inside := false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1  # Layer 1 = Spieler (player._ready)
	monitoring = true
	monitorable = false
	add_to_group(&"mud_zones")  # reduce_slow() bei Mini-Boss-Sieg (M4b)
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = RADIUS
	shape.shape = circle
	add_child(shape)
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)
	_build_visual()


## Pfützen-Form: Kreis mit leichtem Radius-Jitter pro Segment.
func _puddle_points(shrink: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var rng := RandomNumberGenerator.new()
	rng.seed = shape_seed
	for i in _SEGMENTS:
		var angle := TAU * float(i) / float(_SEGMENTS)
		var jitter := rng.randf_range(0.86, 1.06)
		var r := RADIUS * shrink * jitter
		pts.append(Vector2(cos(angle), sin(angle)) * r)
	return pts


func _build_visual() -> void:
	# Bodenfläche (durchscheinend) + dunklerer Kern: lesbarer Schimmer.
	var fill := Polygon2D.new()
	fill.polygon = _puddle_points(1.0)
	fill.color = Color(0.20, 0.18, 0.13, 0.55)
	fill.name = "Fill"
	add_child(fill)
	var core := Polygon2D.new()
	core.polygon = _puddle_points(0.62)
	core.color = Color(0.13, 0.12, 0.09, 0.72)
	core.name = "Core"
	add_child(core)
	# Randlinie als zusätzliches, nicht-farbliches Erkennungsmerkmal.
	var edge := Line2D.new()
	edge.points = _puddle_points(1.0)
	edge.width = 3.0
	edge.closed = true
	edge.default_color = Color(0.30, 0.26, 0.17, 0.9)
	edge.name = "Edge"
	add_child(edge)


## Reduziert die Verlangsamung für den Rest des Runs (M4b: Sieg über
## Poludnitsa schaltet „reduzierte Schlamm-Verlangsamung“ frei).
func reduce_slow(mult: float) -> void:
	slow_pct *= mult


func _physics_process(_delta: float) -> void:
	if _player_inside and is_instance_valid(_player):
		_player.set_area_slow(&"mud", slow_pct)


func _on_area_entered(area: Area2D) -> void:
	if area.has_method("set_area_slow"):
		_player = area
		_player_inside = true


func _on_area_exited(area: Area2D) -> void:
	if area == _player:
		_player_inside = false
		_player = null
