class_name EnemyData
extends Resource
## Gegner-Basiswerte (Technisches Setup §6) – Region-1/Minute-1-normalisiert.
## Regionen- und Zeit-Multiplikatoren kommen erst LAUFZEITIG aus dem
## SpawnDirector dazu (Balancing-Dokument §2, §5).
##
## Tempo ist als Multiplikator auf das Spieler-Basistempo (200 px/s) angegeben,
## NICHT in absoluten Pixeln (Balancing-Dokument §2: „Tempo-Referenz").

enum Role { SWARM, RANGED, FLYER, ELITE, MINIBOSS, BOSS }

@export var id: StringName
@export var display_name: String
@export var role: Role = Role.SWARM
@export var scene: PackedScene
@export var base_hp: float = 8.0
@export var base_damage: float = 5.0
## Multiplikator auf Spieler-Basistempo (200 px/s), z. B. 1.15 = Kikimora.
@export var speed_multiplier: float = 1.15
@export var xp_value: int = 2
@export var gold_value: float = 0.06       # fractional (Balancing §2)
@export var spawn_weight: float = 1.0      # Gewichtung im Regions-Mix (Balancing §3.3)
@export var native_region: int = 1
@export var is_flying: bool = false
@export var has_shield: bool = false
@export var lifesteal: float = 0.0
@export var attack_range: float = 0.0      # > 0 = Fernkämpfer
@export var attack_cooldown: float = 0.0
@export var projectile_scene: PackedScene
@export var signature_sfx: AudioStream


## Effektives Tempo in px/s (Spieler-Basis 200 px/s, Technisches Setup §3.1).
func effective_move_speed() -> float:
	return speed_multiplier * 200.0
