extends BossBase
class_name PoludnitsaBoss
## Poludnitsa – „Mittagsfee“, scripted Mini-Boss von Region 2 (M4b).
##
## Spawn: einmalig bei Minute 6 über region.mini_boss_id (Balancing §3.4).
## Werte (Balancing §6): ~2.600 HP FIX (setup_boss ohne Multiplikatoren),
## Ziel-TTK ~30 s bei ~85 DPS.
##
## Mechanik: Verlangsamungs-Aura (Regionen-Dok §3) – die SPIELFIGUR wird im
## Radius zusätzlich zum Schlamm-Hazard langsamer. Die Aura ist ein
## konstantes Feld: sie läuft auch im Stun (Peruns Zorn) weiter und stirbt
## erst mit ihr (Node-Freigabe). Beim Sieg über sie sinkt die
## Schlamm-Verlangsamung für den Rest des Runs (Buff in
## main._on_miniboss_died).

## Aura-Radius in px (Bereichs-Slow, kein Schaden).
const AURA_RADIUS := 240.0
## Aura-Verlangsamung in % (Startwert – Hebel Playtesting §5).
const AURA_SLOW_PCT := 25.0
const _SEGMENTS := 40


func _ready() -> void:
	super._ready()
	_build_aura()


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	# Aura-Meldung pro Frame, solange das Ziel im Radius ist (Frame-Verfall
	# beim Spieler – entfällt der Aufruf, verlangsamt nichts). Eigener Block
	# nach super(), damit die Aura nicht vom Stun-Return abgeschnitten wird.
	if target == null or not is_instance_valid(target):
		return
	if not target.has_method("set_area_slow"):
		return
	if global_position.distance_to(target.global_position) <= AURA_RADIUS:
		target.set_area_slow(&"poludnitsa", AURA_SLOW_PCT)


## Aura als Bodenring unterhalb des Sprites: Scheibe (Fläche) + Ringlinie als
## nicht-farbiges Erkennungsmerkmal (Barrierefreiheit §3.2: der Radius des
## Effekts ist ablesbar, ohne Farbwahrnehmung zu brauchen).
func _build_aura() -> void:
	var pts := PackedVector2Array()
	for i in _SEGMENTS:
		var angle := TAU * float(i) / float(_SEGMENTS)
		pts.append(Vector2(cos(angle), sin(angle)) * AURA_RADIUS)
	var disc := Polygon2D.new()
	disc.polygon = pts
	disc.color = Color(0.85, 0.78, 0.45, 0.13)
	disc.name = "AuraDisc"
	add_child(disc)
	var ring := Line2D.new()
	ring.points = pts
	ring.width = 3.0
	ring.closed = true
	ring.default_color = Color(0.88, 0.80, 0.45, 0.55)
	ring.name = "AuraRing"
	add_child(ring)
	# Unter den Body legen (Kinder zeichnen in Reihenfolge).
	move_child(ring, 0)
	move_child(disc, 0)
