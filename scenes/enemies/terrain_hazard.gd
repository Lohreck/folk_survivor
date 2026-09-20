extends Area2D
class_name TerrainHazard
## Terrain-Hazard (M2c-3) – von Leshy veränderte Baumformation.
##
## Ablauf (Barrierefreiheit-Dokument §3.2, dreiteilige Struktur):
##   1. VORWARNUNG (0.5 s): Bodenfläche pulsiert (nicht farb-basiert allein –
##      Pulsieren + Größe ändern sich, funktioniert mit Farbenblind-Modus)
##   2. AKTIV: Baumformation erscheint, verursacht Kontaktschaden im Bereich
##   3. DAUERHAFT: Formation bleibt sichtbar, bis sie ersetzt wird
##      (der Leshy ersetzt sie bei der nächsten Terrain-Änderung)
##
## Kollisions-Design: Der Hazard erkennt selbst (maskiert Layer 1 = Spieler).
## Schaden als Tick alle 0.5 s – der Spieler hat ohnehin 0.5 s
## Treffer-Invulnerabilität, schnellere Ticks würden nichts additionalen.

## Schadenst-Tick alle 1 s. WICHTIG: bewusst LANGER als der 0.5-s-Treffer-
## Cooldown des Spielers – ein 0.5-s-Tick kollidiert phasengenau mit der
## Invulnerabilität und würde systematisch geblockt (Playtest-Bug).
const TICK_INTERVAL := 1.0

## Baum-Sprite für die Formation (Platzhalter-Pixelart,
## tools/generate_placeholder_art.gd).
const TREE_TEXTURE := preload("res://assets/sprites/tree.png")

## Schaden pro Tick (wird vom Leshy gesetzt: Terrain-DPS × Tick-Intervall).
var _damage_per_tick := 8.0

var _warn_timer := 0.0
var _active := false
var _tick_timer := 0.0

@onready var _warn_circle: Polygon2D = $WarnCircle
@onready var _trees: Node2D = $Trees


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	monitoring = true
	monitorable = false
	_trees.visible = false
	# Baumformation prozedural streuen (Platzhalter-Look, final kommt Art).
	_build_trees()


func _physics_process(delta: float) -> void:
	if not _active:
		_warn_timer -= delta
		# Vorwarnung: pulsierender Kreis (Barrierefreiheit §3.2: 0.5 s).
		var pulse := 0.28 + 0.22 * sin(Time.get_ticks_msec() * 0.025)
		_warn_circle.modulate.a = pulse
		_warn_circle.scale = Vector2.ONE * (0.85 + pulse * 0.3)
		if _warn_timer <= 0.0:
			_activate()
		return
	# Aktive Phase: Schadenst-Tick, solange der Spieler drin steht.
	_tick_timer -= delta
	if _tick_timer <= 0.0:
		_tick_timer = TICK_INTERVAL
		for area in get_overlapping_areas():
			if area.has_method("take_damage"):
				area.take_damage(_damage_per_tick)


## Startet den Hazard an seiner Position (nach add_child aufrufen).
func begin(warn_time: float, dmg_per_tick: float) -> void:
	_warn_timer = warn_time
	_damage_per_tick = dmg_per_tick


func _activate() -> void:
	_active = true
	_warn_circle.visible = false
	_trees.visible = true
	_tick_timer = TICK_INTERVAL


## Baut 5 Platzhalter-Bäume im Kreis (tree.png-Sprites, leicht rotiert).
func _build_trees() -> void:
	var count := 5
	for i in count:
		var angle := TAU * float(i) / float(count) + randf() * 0.5
		var pos := Vector2.from_angle(angle) * 42.0
		_add_tree(pos)


func _add_tree(pos: Vector2) -> void:
	var tree := Sprite2D.new()
	tree.texture = TREE_TEXTURE
	tree.position = pos
	# Verschiedene Größen/Drehungen für organische Formation.
	tree.scale = Vector2.ONE * randf_range(0.8, 1.2)
	tree.rotation = randf() * TAU
	_trees.add_child(tree)


## Sichtbarer Warnring (0.5 s) + Baumsilhouette als Kinder im .tscn.
