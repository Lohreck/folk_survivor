extends Area2D
class_name TestEnemy
## Platzhalter-Gegner (Kikimora-Referenzwerte aus Balancing §2).
##
## Kollisions-Design (wichtig):
##   Der Gegner erkennt selbst nichts (monitoring = false), er wird umgekehrt
##   von der PlayerHitbox des Spielers erkannt (die maskiert Layer 2).
##   Der Kontaktschaden wird deshalb im Spieler gepollt (get_overlapping_areas),
##   nicht über area_entered auf dem Gegner.

## Multiplikator auf Spieler-Basistempo (200 px/s), z. B. 0.69 = Kikimora.
## Wird beim Spawn aus EnemyData.effective_move_speed() gesetzt.
@export var move_speed := 230.0
## Basis-HP (wird beim Spawn aus EnemyData gesetzt, Kikimora = 8).
@export var max_hp := 8.0
## Basis-Schaden (wird beim Spawn aus EnemyData gesetzt, Kikimora = 5).
@export var contact_damage := 5.0
## XP-Wert (wird beim Spawn aus EnemyData gesetzt, Kikimora = 2).
@export var xp_value := 2.0
## Gold-Wert (wird beim Spawn aus EnemyData gesetzt, Kikimora = 0.06) –
## fraktional; das Run-Crediting summiert und rundet erst beim Run-Ende.
@export var gold_value := 0.0

const _SEPARATION_DISTANCE := 18.0
const _SEPARATION_DISTANCE_SQ := _SEPARATION_DISTANCE * _SEPARATION_DISTANCE
## Gegner halten einen Orbit-Ring um den Spieler statt an der Hitbox zu kleben.
## Radius 20: Gegner berühren die Hitbox (14 + 10 = 24 px Kontaktzone) und
## richten Schaden an, rotieren aber tangential weiter statt statisch zu kleben.
## Klar innerhalb des Axt-Nahbereichs (80 px) – sie werden zuverlässig getroffen.
const _ORBIT_RADIUS := 20.0
## Innerhalb des Bands (Radius ± Band) wird orbitiert, außerhalb angeflogen.
const _ORBIT_BAND := 12.0
## Tangential-Geschwindigkeit beim Umkreisen (px/s).
const _ORBIT_SPEED := 130.0
## Stärke der radialen Korrektur auf den Sollradius (1/s).
const _RADIAL_GAIN := 8.0
## Gewichtung der Separation in px/s (wird auf diese Länge gedeckelt).
const _SEPARATION_WEIGHT := 140.0

## Sog/Pull (M4b, Tag „pull“): alle 6 s den Spieler heranziehen, wenn er
## innerhalb der Reichweite ist (Rusalka „zieht Spieler an“ – Setting §3).
## Die Kraft wirkt als Impuls mit Decay auf der Spieler-Seite.
const PULL_INTERVAL := 6.0
const PULL_RANGE := 420.0
const PULL_FORCE := 400.0

## Stun-Tönung (Peruns Zorn, Waffen-Dok §2.5): lesbares Status-Feedback.
const _STUN_COLOR := Color(0.7, 0.85, 1.6)

## Ziel, das verfolgt wird (der Spieler).
var target: Node2D
## Callback: on_died(enemy) – wird vom Run gesetzt (Drop + Pool-Rückgabe).
var on_died: Callable
## Grid-Cell für die Nachbarschafts-Separation (wird vom Run gesetzt).
var grid_cell := Vector2i.ZERO
## Override für den Orbit-Radius (Fernkämpfer stehen weiter weg, Flieger höher).
## -1 = Standard (_ORBIT_RADIUS), sonst dieser Wert.
var preferred_orbit_radius := -1.0
## Rückzugsschwelle: Unterhalb dieser Distanz läuft der Gegner WEG vom Ziel
## (Fernkämpfer drängen sich nicht an die Nahkampffront). -1 = aus.
var retreat_below := -1.0
## Gegner-Rolle aus der EnemyData (SWARM = Schwarm-Gegner wie Kikimora).
## Wird u. a. vom Charakter-Passiv „Zähe Haut" gelesen (Player).
var enemy_role := EnemyData.Role.SWARM

var _hp := 0.0
var _wander_offset := 0.0
var _flash_time := 0.0
## Knockback-Impuls (px/s), zerfällt über die Zeit.
var _knockback := Vector2.ZERO
## Status-Effekte (M2b/M4d): Verwurzelt (Uralteichen-Axt), Aura
## (Domovoi-Glöckchen), Blutungs-Stapel, Stun (Peruns Zorn).
var _root_time := 0.0
## Aura-Verlangsamung in % (Domovoi-Glöckchen) – pro Frame vom Run gesetzt
## und nach der Bewegung sofort wieder verwertet (Frame-Verfall, M4d).
var _aura_slow_pct := 0.0
## Aktive Blutungs-Stapel: [{dps, time, lifesteal}] – Sichel 1 Stapel,
## Todesschnitt bis 5 (Waffen-Dok §2.4), jeder mit eigenem Timer.
var _bleed_list: Array = []
## Stun (Peruns Zorn, Waffen-Dok §2.5): solange > 0 steht der Gegner still
## und schießt nicht.
var _stun_time := 0.0
## Lifesteal-Anteil (M4b, Upyr „saugt bei Treffer HP ab“): Anteil des vom
## Spieler zugefügten Schadens, der als HP zurückkommt – wird vom Spieler
## in _apply_contact_damage() an den Angreifer zurückgezahlt.
var lifesteal_pct := 0.0
## Pull-Timer (M4b, Tag „pull“) – wird beim Spawn zurückgesetzt.
var _pull_timer := PULL_INTERVAL

@onready var _visual: Sprite2D = $Body
## Standardtextur der Pool-Szene (M4b): gilt/kehrt zurück, wenn die
## EnemyData kein eigenes sprite hat (Pool-Wiederverwendung!).
var _default_texture: Texture2D


func _ready() -> void:
	_wander_offset = randf() * TAU
	collision_layer = 2
	collision_mask = 0
	monitoring = false
	monitorable = true
	_default_texture = _visual.texture


func _physics_process(delta: float) -> void:
	# Aura-Verlangsamung (Domovoi-Glöckchen) einbeziehen und sofort auf 0
	# zurücksetzen – der Run setzt sie pro Frame neu, solange der Gegner im
	# Radius steht; entfällt der Aufruf, verfällt der Effekt automatisch.
	var aura_slow := _aura_slow_pct
	_aura_slow_pct = 0.0
	# Status-Effekte ticken (Blutung = Sichel/Todesschnitt, Verwurzelt =
	# Uralteichen-Axt, Stun = Peruns Zorn).
	if not _bleed_list.is_empty():
		var lifesteal_target := target
		var bleed_total := 0.0
		var heal_total := 0.0
		for i in range(_bleed_list.size() - 1, -1, -1):
			var stack: Dictionary = _bleed_list[i]
			stack["time"] = float(stack["time"]) - delta
			var tick: float = float(stack["dps"]) * delta
			bleed_total += tick
			heal_total += tick * float(stack["lifesteal"]) / 100.0
			if float(stack["time"]) <= 0.0:
				_bleed_list.remove_at(i)
		take_damage(bleed_total)
		# Rusalka-Träna: Anteil des Blutungsschadens als HP zurück. Der
		# Zwischenspeicher der Ziel-Referenz schützt vor dem Pool-Rückgabe-
		# Aufruf innerhalb von take_damage (deactivate() leert target).
		if heal_total > 0.0 and lifesteal_target != null \
				and is_instance_valid(lifesteal_target) \
				and lifesteal_target.has_method("heal"):
			lifesteal_target.heal(heal_total)
		if not visible:
			return  # durch Blutung gestorben
	if _root_time > 0.0:
		_root_time -= delta
	if _flash_time > 0.0:
		_flash_time -= delta
		if _flash_time <= 0.0:
			_visual.modulate = Color.WHITE
	# Stun (Peruns Zorn): Stillstand, kein Schuss, bis der Timer abläuft –
	# nach den Status-Ticks, aber vor Bewegung und _think_extra. Der
	# Weiß-Flash eines Treffers hat Vorrang vor der Stun-Tönung.
	if _stun_time > 0.0:
		_stun_time -= delta
		if _flash_time <= 0.0 and _visual.modulate != _STUN_COLOR:
			_visual.modulate = _STUN_COLOR
		return
	if _visual.modulate == _STUN_COLOR:
		_visual.modulate = Color.WHITE
	if target == null:
		return
	var to_target := target.global_position - global_position
	var target_dist := to_target.length()
	var dir := Vector2.ZERO
	if target_dist >= 0.001:
		dir = to_target / target_dist
	else:
		# Exakte Überlappung mit dem Spieler: deterministische Ausweichrichtung
		# pro Instanz, damit der Gegner den Punkt verlässt statt einzufrieren.
		dir = Vector2.RIGHT.rotated(float(get_instance_id() % 628) / 100.0)
	# Tangentenrichtung: Alle Gegner kreisen GLEICH herum (kohärenter Ring
	# statt chaotischem Gegeneinander, das Gegner radial herausdrückt).
	# Organik kommt weiterhin aus Wander-Drift (Anflug) + Separation.
	var tangent := dir.rotated(PI / 2.0)

	var velocity := Vector2.ZERO
	var orbit_radius := _ORBIT_RADIUS if preferred_orbit_radius < 0.0 else preferred_orbit_radius
	var in_retreat := retreat_below > 0.0 and target_dist < retreat_below
	if target_dist > orbit_radius + _ORBIT_BAND:
		# Anflug: zum Ziel, mit Wander-Drift für organische Schwarmbewegung.
		var chase := dir.rotated(sin(Time.get_ticks_msec() / 1000.0 + _wander_offset) * 0.3)
		velocity = chase * move_speed
	elif in_retreat:
		# Rückzugs-Modus (Fernkämpfer): WEG vom Ziel, gleiche Bandlogik
		# invertiert – weglaufen, bis die Schwelle wieder erreicht ist.
		velocity = -dir * move_speed
	else:
		# Orbit-Band: tangential kreisen + sanft auf den Sollradius regeln.
		# HINWEIS Vorzeichen: dir zeigt ZUM Spieler. radial_error > 0 heisst
		# „zu nah" -> also VON ihm weg (-dir); radial_error < 0 heisst „zu weit"
		# -> ZU ihm hin (+dir). Deshalb das Minus.
		var radial_error := orbit_radius - target_dist
		velocity = tangent * _ORBIT_SPEED - dir * (radial_error * _RADIAL_GAIN)

	# Weiche Separation dazu (normiert gewichtet, nicht richtungsdominant).
	var sep := _separation_from_neighbors()
	if sep != Vector2.ZERO:
		velocity += sep.normalized() * minf(sep.length() * 200.0, _SEPARATION_WEIGHT)

	# Verwurzelt-Debuff: -30 % Tempo (Uralteichen-Axt-Effekt).
	if _root_time > 0.0:
		velocity *= 0.7
	# Aura-Verlangsamung (Domovoi-Glöckchen): Prozent des Tempos abziehen.
	if aura_slow > 0.0:
		velocity *= 1.0 - clampf(aura_slow / 100.0, 0.0, 0.9)

	# Gesamtgeschwindigkeit auf das eigene Tempo deckeln (kein Turbo-Stacking).
	if velocity.length() > move_speed:
		velocity = velocity.normalized() * move_speed

	# Knockback NACH dem Deckel addieren – als eigener Impuls, der die normale
	# Bewegung überlagert (sonst würde der Deckel ihn komplett schlucken).
	if _knockback != Vector2.ZERO:
		velocity += _knockback
		_knockback = _knockback.move_toward(Vector2.ZERO, 600.0 * delta)

	if velocity != Vector2.ZERO:
		global_position += velocity * delta
		# Figur bleibt aufrecht; Blickrichtung nur horizontal spiegeln
		# (Diablo-Stil – kein Wetterfahnen-Drehen mehr).
		if velocity.x < 0.0:
			_visual.flip_h = true
		elif velocity.x > 0.0:
			_visual.flip_h = false

	# Hook für Unterklassen (Fernkampf-Schusslogik etc.).
	_think_extra(delta, target_dist, dir)

	# Sog-Pull (M4b, Tag „pull“): Rusalka zieht den Spieler periodisch zu
	# sich heran (Setting §3 „zieht Spieler an“). Kraft = Impuls beim
	# Spieler mit Decay; der Timer tickt weiter, damit der Rhythmus
	# vorhersehbar bleibt (Auslösung erst bei Reichweite).
	if has_tag(&"pull"):
		_pull_timer -= delta
		if _pull_timer <= 0.0:
			_pull_timer = PULL_INTERVAL
			if target_dist <= PULL_RANGE and target.has_method("apply_pull"):
				target.apply_pull(global_position, PULL_FORCE)


## Hook: Unterklassen (z. B. RangedEnemy) implementieren hier Zusatzlogik,
## die den Basis-Tick nicht ersetzt, sondern ergänzt (Schießen, Aufladen etc.).
func _think_extra(_delta: float, _target_dist: float, _dir: Vector2) -> void:
	pass


## Knockback (Uralteichen-Axt): Impuls weg von der Quelle.
func apply_knockback(from_position: Vector2, force: float) -> void:
	var dir := (global_position - from_position).normalized()
	_knockback += dir * force


## Verwurzelt-Debuff (Uralteichen-Axt): -30 % Tempo für die Dauer.
func apply_root(duration: float) -> void:
	_root_time = duration


## Blutung: DoT über die Dauer, bis zu max_stacks parallel (Sichel 1,
## Todesschnitt 5 – Waffen-Dok §2.4). Bei vollem Limit wird der älteste
## Stapel aufgefrischt (DPS/Lifesteal maxf – Altverhalten des Einzel-DoT).
## lifesteal_pct = Anteil des Blutungsschadens, der als HP zurückkommt
## (Rusalka-Träna, Waffen-Dok §3).
func apply_bleed(dps: float, duration: float, lifesteal_pct := 0.0, max_stacks := 1) -> void:
	var cap := maxi(max_stacks, 1)
	if _bleed_list.size() >= cap:
		var oldest: Dictionary = _bleed_list[0]
		oldest["dps"] = maxf(float(oldest["dps"]), dps)
		oldest["time"] = duration
		oldest["lifesteal"] = maxf(float(oldest["lifesteal"]), lifesteal_pct)
		return
	_bleed_list.append({"dps": dps, "time": duration, "lifesteal": lifesteal_pct})


## Stun (Peruns Zorn): Stillstand für die Dauer (Waffen-Dok §2.5).
func apply_stun(duration: float) -> void:
	_stun_time = maxf(_stun_time, duration)


## Gegner-Tag für Waffen-Bonus-Prüfung (z. B. hausgeist beim Segenshufeisen,
## wasser/geist beim Lodernden Weihwasser – Waffen-Dok §2.2/§2.3).
func has_tag(tag: StringName) -> bool:
	return tag in enemy_tags


## Lifesteal (M4b, Upyr): um `amount` heilen, gedeckelt auf die Maximal-HP.
## Aufrufseite: Spieler in _apply_contact_damage().
func heal(amount: float) -> void:
	if not visible:
		return
	_hp = minf(_hp + amount, max_hp)


## Aura-Verlangsamung (Domovoi-Glöckchen): Prozent, die IN DIESEM Frame
## greifen – wird vom Run pro Frame neu gesetzt, solange der Gegner im
## Radius ist (ohne Gegenaufruf verfällt der Effekt nach einem Frame).
func apply_aura_slow(pct: float) -> void:
	_aura_slow_pct = maxf(_aura_slow_pct, pct)


## Separation: nur gegen Gegner derselben und der 8 Nachbar-Gridzellen.
## O(1) pro Gegner dank Uniform-Grid (Technisches Konzept §3: kein N²-Loop).
func _separation_from_neighbors() -> Vector2:
	var force := Vector2.ZERO
	var grid: Dictionary = get_meta("enemy_grid", {})
	if grid.is_empty():
		return force
	for dx in [-1, 0, 1]:
		for dy in [-1, 0, 1]:
			var cell := grid_cell + Vector2i(dx, dy)
			if not grid.has(cell):
				continue
			for other in grid[cell]:
				if other == self or not is_instance_valid(other):
					continue
				var diff: Vector2 = global_position - other.global_position
				var dist_sq: float = diff.length_squared()
				if dist_sq < _SEPARATION_DISTANCE_SQ and dist_sq > 0.0001:
					# Stärker wegschieben, je enger der Nachbar.
					force += diff.normalized() * (1.0 - sqrt(dist_sq) / _SEPARATION_DISTANCE)
	return force.limit_length(1.5)


## Schaden zufügen; bei Tod Drop-Callback + Pool-Rückgabe.
func take_damage(amount: float) -> void:
	_hp -= amount
	if _hp <= 0.0:
		if on_died.is_valid():
			on_died.call(self)
		EnemyPoolManager.return_instance(self)
	else:
		# Treffer-Feedback: kurzer weißer Blitz.
		_visual.modulate = Color(2.0, 2.0, 2.0)
		_flash_time = 0.08


## Run-Daten anwenden (vom SpawnDirector beim Spawn aufgerufen).
## data     = EnemyData-Resource (Basiswerte, Region-1/Minute-1-normalisiert)
## hp_mult  = Region-Multiplikator × Zeit-Multiplikator (Balancing §5/§4)
## dmg_mult = dito für den Schaden
## Elite-Markierung (Balancing §6) – u. a. Basis für „Kampferfahrung“
## (Soldat: +5 % Schaden gegen Elite/Boss, Charaktere-Dokument §2.2).
var is_elite := false
## Quell-Kennung aus der EnemyData (Telemetrie §4 death_cause: „Gegnertyp/
## Schaden“). Wird beim Spawn gesetzt und mit jeder Schadensquelle an den
## Spieler durchgereicht (Kontakt, Fernkampf-Projektil).
var source_id: StringName = &""
## Gegner-Tags aus der EnemyData (Waffen-Boni, Waffen-Dok §2.2/§2.3) –
## u. a. Basis für element_bonus_vs() der Waffen (M4d).
var enemy_tags: PackedStringArray


## elite    = true → ×10 HP (Balancing §6: Elite-TTK/Trash-TTK ≈ 10)
func setup_from_data(data: EnemyData, hp_mult: float, dmg_mult: float, elite: bool) -> void:
	is_elite = elite
	source_id = data.id
	enemy_tags = data.tags
	lifesteal_pct = data.lifesteal
	max_hp = data.base_hp * hp_mult * (10.0 if elite else 1.0)
	contact_damage = data.base_damage * dmg_mult
	enemy_role = data.role
	xp_value = float(data.xp_value)
	gold_value = data.gold_value
	move_speed = data.effective_move_speed()
	# Eigenes Sprite (M4b): ohne data.sprite kehrt die Standardtextur der
	# Pool-Szene zurück – sonst sieht der nächste Nutzer der Instanz alt aus.
	_visual.texture = data.sprite if data.sprite != null else _default_texture
	# _hp wird in activate() auf max_hp gesetzt – dort auch die Daten berücksichtigen.
	_hp = max_hp


## Pool-Schnittstelle: Instanz in den aktiven Zustand versetzen.
func activate() -> void:
	# Status-Effekte der Vor-Nutzung nicht mit in die nächste Runde nehmen
	# (Pool-Wiederverwendung): Blutungs-Stapel, Stun, Verwurzelt, Aura,
	# Rückstoß.
	_bleed_list.clear()
	_stun_time = 0.0
	_root_time = 0.0
	_aura_slow_pct = 0.0
	_knockback = Vector2.ZERO
	lifesteal_pct = 0.0
	_pull_timer = PULL_INTERVAL
	visual_flash_reset()
	visible = true
	set_physics_process(true)
	set_deferred("monitorable", true)


## Stellt die Grundfarbe nach einem Treffer-Blitz wieder her.
func visual_flash_reset() -> void:
	_visual.modulate = Color.WHITE
	_flash_time = 0.0


## Pool-Schnittstelle: Instanz parken (unsichtbar, keine Prozesse, keine Kollision).
func deactivate() -> void:
	# Ziel und Callback leeren – sonst behält eine recycelte Instanz ein
	# veraltetes Ziel (und würde sofort wieder loslaufen).
	target = null
	on_died = Callable()
	visible = false
	set_physics_process(false)
	set_deferred("monitorable", false)
	global_position = Vector2(-10000, -10000)
