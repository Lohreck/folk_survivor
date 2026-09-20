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

const TICK_INTERVAL := 0.5

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


## Baut 5 Platzhalter-Bäume im Kreis (trunk + Krone als Polygon2D).
func _build_trees() -> void:
	var count := 5
	for i in count:
		var angle := TAU * float(i) / float(count) + randf() * 0.5
		var pos := Vector2.from_angle(angle) * 42.0
		_add_tree(pos)


func _add_tree(pos: Vector2) -> void:
	var trunk := Polygon2D.new()
	trunk.color = Color(0.32, 0.22, 0.12)
	trunk.polygon = PackedVector2Array([
		pos + Vector2(-3, 4), pos + Vector2(3, 4),
		pos + Vector2(2, -10), pos + Vector2(-2, -10),
	])
	_trees.add_child(trunk)
	var canopy := Polygon2D.new()
	canopy.color = Color(0.18, 0.38, 0.16)
	canopy.polygon = PackedVector2Array([
		pos + Vector2(0, -44), pos + Vector2(18, -12), pos + Vector2(-18, -12),
	])
	_trees.add_child(canopy)


## Sichtbarer Warnring (0.5 s) + Baumsilhouette als Kinder im .tscn.
