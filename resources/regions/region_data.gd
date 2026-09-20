class_name RegionData
extends Resource
## Regions-Definition (Technisches Setup §6, Balancing §3 & §5).
## Alle Multiplikatoren multiplizieren sich auf die EnemyData-Basiswerte.

@export var id: StringName
@export var display_name: String
@export var map_scene: PackedScene
## Grundschwierigkeit der Region (Balancing §5): Region 1 = 1.0 / 1.0.
@export var hp_multiplier: float = 1.0
@export var damage_multiplier: float = 1.0
## Spawn-Basis in Gegnern pro Sekunde bei Minute 1 (Balancing §3.1).
@export var spawn_basis: float = 1.5
## Gegner-Mix dieser Region (Balancing §3.3).
@export var enemy_spawn_table: Array[EnemySpawnEntry] = []
@export var mini_boss_id: StringName                    # leer = kein Mini-Boss (Region 1)
@export var main_boss_id: StringName
@export var unlock_condition: StringName
