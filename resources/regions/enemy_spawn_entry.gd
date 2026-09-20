class_name EnemySpawnEntry
extends Resource
## Eintrag im Regions-Mix (Technisches Setup §6): Gegnertyp + Gewicht.
## Gewichte sind relativ – der SpawnDirector normalisiert sie selbst.

@export var enemy: EnemyData
@export var weight: float = 1.0
## Ab dieser Run-Minute darf der Typ erscheinen (0 = sofort, Balancing §3.3).
@export var from_minute: float = 0.0
## Elite-Spawns erscheinen erst ab Minute 5 (Balancing §6).
@export var is_elite: bool = false
