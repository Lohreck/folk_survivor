extends TestEnemy
class_name LeshyBoss
## Leshy – Hauptboss Region 1 „Dammerwald" (M2c-3).
##
## Mechanik (Setting/Regionen-Dokument): Terrain-Veränderung statt reiner
## Angriffsmuster – verlangt räumliches Ausweichen. Zyklus:
##   alle TERRAIN_INTERVAL s: Warnung (0.5 s Puls) -> neue Baumformation
##   (TerrainHazard). Die alte Formation wird ersetzt und bleibt bis dahin
##   sichtbar (Barrierefreiheit §3.2: „bleibt sichtbar bis zur nächsten Änderung").
##
## Werte (Balancing §6): ~19.000 HP FIX – Boss-HP ist NICHT vom Zeit-Multi-
## plikator betroffen (Region-Multiplikator eingerechnet) -> Spawndaten mit
## hp_mult/dmg_mult = 1.0. Ziel-TTK ~50 s bei ~380 DPS.
## Der Boss ist gepoolt-technisch NICHT gepoolt (einzige Instanz pro Run).

const HAZARD_SCENE := preload("res://scenes/enemies/terrain_hazard.tscn")
## Terrain-Änderungs-Zyklus (s). Erste Änderung kürzer, damit der Spieler die
## Mechanik früh lernt (Tutorial-Region).
const TERRAIN_INTERVAL := 7.0
## Schaden pro Terrain-Tick (8 alle 0.5 s = 16 DPS im Hazard).
const TERRAIN_TICK_DAMAGE := 8.0
## Warnzeit (Barrierefreiheit §3.2: 0.5 s Vorwarnung).
const TERRAIN_WARN := 0.5

var _terrain_timer := 3.0
var _active_hazard: TerrainHazard


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	# Leshy ist eine Baumformation – kein rotationierender Schwarm-Pfeil.
	rotation = 0.0


func _think_extra(delta: float, _target_dist: float, _dir: Vector2) -> void:
	_terrain_timer -= delta
	if _terrain_timer > 0.0:
		return
	_terrain_timer = TERRAIN_INTERVAL
	_change_terrain()


## Terrain-Veränderung: Neue Formation nahe am Spieler (gezielt, aber fair:
## 0.5 s Vorwarnung + 40–140 px Streuung, kein Punkt-Blitzschlag).
func _change_terrain() -> void:
	# Alte Formation ersetzen („bleibt sichtbar bis zur nächsten Änderung").
	if _active_hazard != null and is_instance_valid(_active_hazard):
		_active_hazard.queue_free()
	_active_hazard = null
	var anchor: Vector2 = global_position
	if target != null:
		anchor = target.global_position
	var pos: Vector2 = anchor + Vector2.from_angle(randf() * TAU) * randf_range(40.0, 140.0)
	if has_meta("arena_size"):
		var arena: Vector2 = get_meta("arena_size")
		pos = pos.clamp(Vector2(32, 32), arena - Vector2(32, 32))
	var hazard: TerrainHazard = HAZARD_SCENE.instantiate()
	get_parent().add_child(hazard)
	hazard.global_position = pos
	hazard.begin(TERRAIN_WARN, TERRAIN_TICK_DAMAGE)
	_active_hazard = hazard


## Boss ist nicht Teil des Gegner-Pools: bei Tod kein Pool-Return, sondern
## Freigabe + Hazards aufräumen (sonst bleibt die Formation für immer stehen).
func take_damage(amount: float) -> void:
	_hp -= amount
	if _hp <= 0.0:
		if _active_hazard != null and is_instance_valid(_active_hazard):
			_active_hazard.queue_free()
		if on_died.is_valid():
			on_died.call(self)
		queue_free()
	else:
		_visual.modulate = Color(2.0, 2.0, 2.0)
		_flash_time = 0.08


## HUD-Boszbalken (Wert 0–1). Public-Getter, da _hp bewusst privat ist.
func hp_ratio() -> float:
	return clampf(_hp / max_hp, 0.0, 1.0)
