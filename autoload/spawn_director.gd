extends Node
## SpawnDirector (Autoload) – Kernformeln aus dem Balancing-Dokument §3, §4 & §5.
##
## Drei Skalierungs-Achsen multiplizieren sich (Balancing §1):
##   Zeit im Run (pro Minute, stückweise Kurve mit Spikes)  -> hier
##   Region (HP/Damage-Multiplikatoren)                     -> RegionData
##   Gegnertyp (Basiswerte)                                 -> EnemyData
##
## Weiches Ende (Balancing §3.4): Spawn-Rate friert bei Minute 9 ein,
## bei Minute 10 stoppt das Spawnen (Boss-Slot).

## Spieler-Basistempo in px/s – Referenz für Gegner-Tempo-Multiplikatoren.
const PLAYER_BASE_SPEED := 200.0

## Harte Obergrenze aktiver Gegner (Balancing §1: „85", Deckel im Pool: 100).
const HARD_ENEMY_CAP := 85
## Rampe des aktiven Deckels: min(85, 15 + 8 × Minute) (Balancing §3.2).
const ACTIVE_CAP_BASE := 15
const ACTIVE_CAP_PER_MINUTE := 8.0

## Spawn-Rate friert ab Minute 9 ein, Stat-Skalierung ab Minute 10 (Balancing §3.4).
const SPAWN_FREEZE_MINUTE := 9
const SCALE_FREEZE_MINUTE := 10

## Stückweise HP-Kurve (Balancing §4): Basiswachstum ×1.10/Minute,
## multiplikative Spikes an festen Marken (Minute 3/5/7/10).
const HP_BASE_GROWTH := 1.10
const HP_SPIKES := {
	3: 1.08,
	5: 1.10,
	7: 1.10,
	10: 1.15,
}
## Schaden skaliert linear (verhindert One-Shots ab Minute 8, Balancing §4).
const DAMAGE_PER_MINUTE := 0.03

## Aktive Region (wird vom Run gesetzt).
var region: RegionData

## Intern: laufende Spawn-Akkumulatoren (fraktionale Spawns pro Tick).
var _spawn_accumulator := 0.0
var _elite_timer := 0.0
## Nächster regulärer Elite-Spawn (Balancing §6: ab Minute 5, danach 60–90 s).
var _next_elite_minute := 5.0


## HP-Multiplikator der aktuellen Run-Minute (Balancing §4, Tabelle exakt).
func hp_multiplier_for(minute: float) -> float:
	var m := clampf(minute, 1.0, float(SCALE_FREEZE_MINUTE))
	var mult := 1.0
	var whole := int(m)
	# Basiswachstum pro abgelaufener Minute.
	mult *= pow(HP_BASE_GROWTH, float(whole - 1))
	# Fraktionaler Anteil interpoliert auf den nächsten Minute-Schritt.
	var frac := m - float(whole)
	if frac > 0.0:
		mult *= lerp(1.0, HP_BASE_GROWTH, frac)
	# Multiplikative Spikes an festen Marken (alle Spikes <= aktueller Minute).
	for spike_minute: int in HP_SPIKES:
		if whole >= spike_minute:
			mult *= HP_SPIKES[spike_minute]
	return mult


## Schaden-Multiplikator der aktuellen Run-Minute (Balancing §4: linear).
func damage_multiplier_for(minute: float) -> float:
	var m := clampf(minute, 1.0, float(SCALE_FREEZE_MINUTE))
	return 1.0 + DAMAGE_PER_MINUTE * (m - 1.0)


## Spawn-Rate in Gegnern/s für Minute t (Balancing §3.1), eingefroren ab Min. 9.
func spawn_rate_for(minute: float) -> float:
	if region == null:
		return 0.0
	var m := clampf(minute, 1.0, float(SPAWN_FREEZE_MINUTE))
	return region.spawn_basis * (1.0 + 0.30 * (m - 1.0))


## Aktiver-Gegner-Deckel für Minute t (Balancing §3.2), hart bei 85.
func active_cap_for(minute: float) -> int:
	var m := clampf(minute, 1.0, float(SPAWN_FREEZE_MINUTE))
	return mini(HARD_ENEMY_CAP, ACTIVE_CAP_BASE + int(ACTIVE_CAP_PER_MINUTE * m))


## Ist die Spawn-Phase beendet (Minute 10 = Boss)? (Balancing §3.4)
func spawning_finished(minute: float) -> bool:
	return minute >= 10.0


## Würfelt aus dem Regions-Mix den nächsten Gegnertyp (Balancing §3.3).
## Gewichte normalisiert; Einträge mit from_minute > aktueller Minute ausgeschlossen.
func pick_enemy_type(minute: float) -> EnemyData:
	if region == null or region.enemy_spawn_table.is_empty():
		return null
	var total := 0.0
	for entry in region.enemy_spawn_table:
		if entry.from_minute <= minute:
			total += entry.weight
	if total <= 0.0:
		return null
	var roll := randf() * total
	for entry in region.enemy_spawn_table:
		if entry.from_minute > minute:
			continue
		roll -= entry.weight
		if roll <= 0.0:
			return entry.enemy
	# Rundungssicherer Fallback: letzter gültiger Eintrag.
	for entry in region.enemy_spawn_table:
		if entry.from_minute <= minute:
			return entry.enemy
	return null


## Setzt die aktive Region (vom Run beim Start aufgerufen).
func set_region(data: RegionData) -> void:
	region = data
	_spawn_accumulator = 0.0
	_elite_timer = 0.0
	_next_elite_minute = 5.0


## Zentrale Spawn-Logik pro Physik-Tick (vom Run aufgerufen).
## Gibt die Anzahl der in diesem Tick zu spawnenden Gegner zurück.
## active_count = aktuell aktive Gegner (für den Deckel).
func tick_spawning(delta: float, minute: float, active_count: int) -> int:
	if region == null or spawning_finished(minute):
		return 0
	var cap := active_cap_for(minute)
	if active_count >= cap:
		return 0
	var rate := spawn_rate_for(minute)
	_spawn_accumulator += rate * delta
	var spawned := 0
	while _spawn_accumulator >= 1.0 and active_count + spawned < cap:
		_spawn_accumulator -= 1.0
		spawned += 1
	return spawned


## Elite-Spawn-Timer (Balancing §6: ab Minute 5, danach alle 60–90 s).
## true = dieser Tick soll einen Elite spawnen.
func tick_elite(delta: float, minute: float) -> bool:
	if minute < _next_elite_minute or spawning_finished(minute):
		return false
	_next_elite_minute = minute + randf_range(1.0, 1.5)  # 60–90 s in Minuten
	return true


## Reset pro Run-Start.
func reset() -> void:
	_spawn_accumulator = 0.0
	_elite_timer = 0.0
	_next_elite_minute = 5.0
