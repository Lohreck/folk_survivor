extends BossBase
class_name BabaYagaBoss
## Baba Yaga – Hauptboss Region 2 „Das Sumpfmoor" (M4b).
##
## Mechanik (Regionen-Dok §3): Safe-Zone mit Rezentrierung – alle CAST_GAP s
## wird ein sicherer Kreis AUF DER SPIELERPOSITION gecastet, dessen Radius
## stufenweise schrumpft (520 -> 430 -> 340 -> 250 px). Wer außerhalb steht,
## bekommt Tick-Schaden (Quelle `baba_yaga_zone` für death_cause §4). Nach
## der letzten Stufe folgt Pause + Neucast auf der aktuellen Position.
##
## Ablauf pro Stufe (Barrierefreiheit §3.2, dreiteilige Struktur):
##   1. WARNUNG: Ring pulst + Geisterring der ZUKÜNFTIGEN Größe blendet ein
##   2. AKTIV: neue Radiusgröße gilt, Schaden außerhalb
##   3. DIE GRÖSSE BLEIBT sichtbar bis zur nächsten Stufe
##
## Steuerung läuft komplett in _think_extra: im Stun (Peruns Zorn) friert
## die Zone ein – Zustand, Timer und Schaden bleiben unverändert stehen.
##
## Werte (Balancing §6): 23.000 HP FIX (setup_boss ohne Multiplikatoren),
## Ziel-TTK ~55 s bei ~420 DPS; Kontakt 18.

## Radiusfolge der Safe-Zone in px (Start groß, End eng).
const ZONE_RADII := [520.0, 430.0, 340.0, 250.0]
## Zeit je Stufe in s: ZONE_WARN davon ist die Warnphase vor der Verkleinerung.
const ZONE_STEP_TIME := 2.6
const ZONE_WARN := 0.8
## Pause zwischen den Sequenzen (Rezentrierung auf die Spielerposition).
const ZONE_GAP := 1.6
## Startverzögerung nach dem Spawn bis zum ersten Cast.
const ZONE_CAST_DELAY := 4.0
## Schaden pro Tick außerhalb (Startwert, Hebel §5). Tick 1.0 s – bewusst
## länger als die 0.5-s-Treffer-Invulnerabilität, sonst würde er
## phasengenau geblockt (Playtest-Bug beim Terrain-Hazard).
const ZONE_TICK_DPS := 10.0
const ZONE_TICK_INTERVAL := 1.0
const _SEGMENTS := 48

## Timer bis zum nächsten Phasenwechsel (Cast-Start, Warn-Ende, Stufen-Ende,
## Gap-Ende) – je nach _zone_active/_zone_warn-Bedeutung.
var _zone_timer := ZONE_CAST_DELAY
var _zone_active := false
var _zone_warn := false
var _zone_step := 0
var _zone_center := Vector2.ZERO
var _zone_tick := ZONE_TICK_INTERVAL
## Zone-Visuelle, liegt als eigener Node im Eltern-Container (Zentrum und
## Boss-Position sind unabhängig voneinander).
var _zone_visual: Node2D
var _zone_disc: Polygon2D
var _zone_ring: Line2D
var _zone_ghost: Line2D


func _ready() -> void:
	super._ready()
	_build_zone_visual()


func _on_death_cleanup() -> void:
	if _zone_visual != null and is_instance_valid(_zone_visual):
		_zone_visual.queue_free()
	_zone_visual = null


func _think_extra(delta: float, _target_dist: float, _dir: Vector2) -> void:
	_update_zone(delta)


## Zone-Zustandsmaschine. Nur hier, solange sie nicht gestunnt ist.
func _update_zone(delta: float) -> void:
	if not _zone_active:
		_zone_timer -= delta
		if _zone_timer <= 0.0:
			_start_zone()
		return
	if _zone_warn:
		# Warnphase: Pulsieren (nicht-farbliche Änderung, §3.2) bis zur
		# Verkleinerung. Nur erreichbar, solange noch eine Stufe folgt.
		var pulse := 0.35 + 0.4 * sin(Time.get_ticks_msec() * 0.025)
		_zone_ring.modulate.a = pulse
		_zone_disc.modulate.a = 0.5 + pulse * 0.5
		_zone_timer -= delta
		if _zone_timer > 0.0:
			return
		_zone_warn = false
		_zone_step += 1
		_zone_timer = ZONE_STEP_TIME - ZONE_WARN
		_apply_zone_shape()
		return
	_zone_timer -= delta
	if _zone_timer <= 0.0:
		if _zone_step >= ZONE_RADII.size() - 1:
			_finish_zone()  # Letzte Stufe abgelaufen -> Pause + Neucast
			return
		# Warnphase vor der nächsten Verkleinerung einleiten.
		_zone_warn = true
		_zone_timer = ZONE_WARN
		_zone_ghost.visible = true
		_zone_ghost.points = _circle_points(ZONE_RADII[_zone_step + 1])
	# Schadenstick, solange die Sequenz läuft (auch in der Warnphase).
	_zone_tick -= delta
	if _zone_tick <= 0.0:
		_zone_tick = ZONE_TICK_INTERVAL
		_apply_zone_damage()


## Neue Sequenz: sicherer Kreis um die aktuelle Spielerposition.
func _start_zone() -> void:
	_zone_active = true
	_zone_warn = false
	_zone_step = 0
	_zone_center = target.global_position
	_zone_timer = ZONE_STEP_TIME - ZONE_WARN
	_zone_tick = ZONE_TICK_INTERVAL
	_zone_visual.position = _zone_center
	_zone_visual.visible = true
	_apply_zone_shape()


## Sequenzende: Visuelle aus, kurze Pause, danach Rezentrierung.
func _finish_zone() -> void:
	_zone_active = false
	_zone_warn = false
	_zone_timer = ZONE_GAP
	_zone_visual.visible = false


## Radius und Position der Zone übernehmen (Größe bleibt bis zur nächsten
## Stufe sichtbar).
func _apply_zone_shape() -> void:
	_zone_visual.position = _zone_center
	var pts := _circle_points(ZONE_RADII[_zone_step])
	_zone_disc.polygon = pts
	_zone_ring.points = pts
	_zone_ghost.visible = false
	_zone_ring.modulate.a = 1.0
	_zone_disc.modulate.a = 1.0


## Tick-Schaden, wenn die Figur außerhalb des sicheren Kreises steht.
func _apply_zone_damage() -> void:
	if target == null or not is_instance_valid(target):
		return
	if target.global_position.distance_to(_zone_center) > ZONE_RADII[_zone_step]:
		target.take_damage(ZONE_TICK_DPS, &"baba_yaga_zone")


## Zone visuell: Scheibe (sicherer Bereich) + Ringlinie als nicht-farbiges
## Erkennungsmerkmal + Geisterring für die kommende Größe (Warnung).
func _build_zone_visual() -> void:
	_zone_visual = Node2D.new()
	_zone_visual.name = "BabaYagaZone"
	_zone_visual.visible = false
	get_parent().add_child(_zone_visual)
	_zone_disc = Polygon2D.new()
	_zone_disc.color = Color(0.55, 0.75, 0.55, 0.10)
	_zone_disc.name = "ZoneDisc"
	_zone_visual.add_child(_zone_disc)
	_zone_ring = Line2D.new()
	_zone_ring.width = 4.0
	_zone_ring.closed = true
	_zone_ring.default_color = Color(0.75, 0.90, 0.65, 0.8)
	_zone_ring.name = "ZoneRing"
	_zone_visual.add_child(_zone_ring)
	_zone_ghost = Line2D.new()
	_zone_ghost.width = 3.0
	_zone_ghost.closed = true
	_zone_ghost.default_color = Color(0.95, 0.55, 0.30, 0.7)
	_zone_ghost.name = "ZoneGhost"
	_zone_ghost.visible = false
	_zone_visual.add_child(_zone_ghost)


func _circle_points(radius: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in _SEGMENTS:
		var angle := TAU * float(i) / float(_SEGMENTS)
		pts.append(Vector2(cos(angle), sin(angle)) * radius)
	return pts
