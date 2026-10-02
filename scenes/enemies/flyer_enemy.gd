extends RangedEnemy
class_name FlyerEnemy
## Fliegender Gegner (M2c-2) – Basis für Aitvaras (Hausgeist-Drache).
##
## Verhalten (Setting-Dokument: „spuckt kleine Feuerprojektile"):
##   Erbt die komplette Schusslogik von RangedEnemy (Anflug -> Schussdistanz
##   halten -> Schießen) und ergänzt das Fliegen:
##     – Weiterer Orbit-Radius (kreist außerhalb der Bodenkämpfer-Front)
##     – Schweben: sinusförmiges Auf/Ab des Sprites (rein visuell, die
##       Kollisionsfläche bleibt stabil – wichtig für faire Treffer)
##   Aus Technisches Setup §3.2: Kollisionsradius 16, Tempo 130 px/s
##   (speed_multiplier 0.65 aus der EnemyData).
##
## Elite-Verwendung (Balancing §3.3): Aitvaras-Gruppe ab Minute 5 als erste
## Elite (×10 HP via setup_from_data) – gleiche Szene, nur andere Werte.

## Schweben: Amplitude (px) und Frequenz (Hz) des Auf/Ab.
const _HOVER_AMPLITUDE := 6.0
const _HOVER_SPEED := 3.0

## Flieger kreisen weiter außen als Bodenkämpfer (125 px), aber noch IN der
## Schussreichweite (attack_range = 180 aus der EnemyData) und in der
## Reichweite der Startwaffen (Playtest 2026-10-02: 150 → 135 px).
const _FLY_ORBIT_RADIUS := 135.0
## Rückzugsschwelle niedriger als beim Domovoi: Flieger scheuen den
## Nahkontakt weniger (sie sind ohnehin schnell wieder draußen).
const _FLY_RETREAT_BELOW := 60.0

## Schwebephase (rad). Versetzt pro Instanz – nicht alle wippen im Gleichtakt.
var _hover_time := 0.0

@onready var _body_visual: Sprite2D = $Body
@onready var _rim_visual: Sprite2D = get_node_or_null("Rim")


func _ready() -> void:
	super._ready()
	# Flieger-Profil: weiter außen kreisen, weniger Nahkontaktscheu.
	preferred_orbit_radius = _FLY_ORBIT_RADIUS
	retreat_below = _FLY_RETREAT_BELOW
	_hover_time = randf() * TAU


func _physics_process(delta: float) -> void:
	_hover_time += delta * _HOVER_SPEED
	# Schweben NUR auf dem Sprite (Kollision bleibt auf der Boden-Ebene,
	# sonst wäre der Flieger schwerer zu treffen als beabsichtigt).
	var bob := sin(_hover_time) * _HOVER_AMPLITUDE
	if _body_visual != null:
		_body_visual.position.y = bob
	if _rim_visual != null:
		_rim_visual.position.y = bob
	super._physics_process(delta)


func setup_from_data(data: EnemyData, hp_mult: float, dmg_mult: float, elite: bool) -> void:
	super.setup_from_data(data, hp_mult, dmg_mult, elite)
	# Schwebephase beim Spawn neu würfeln (versetztes Auf/Ab im Schwarm).
	_hover_time = randf() * TAU
