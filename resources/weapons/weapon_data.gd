class_name WeaponData
extends Resource
## Waffen-Definition (Technisches Setup §6).
## DPS-Kurve über Level: base_damage × 1.30^(level-1) (Balancing §8).
## Level 1–8 (max_level), danach nur noch Evolution (Waffen-Dokument §1).

enum Type { MELEE_ARC, BLEED_MELEE, CHAIN }

@export var id: StringName
@export var display_name: String
## Verhaltens-Typ der Waffe (steuert die konkrete Waffenszene/Logik).
@export var weapon_type: Type = Type.MELEE_ARC
@export var scene: PackedScene
@export var base_damage: float = 10.0
@export var cooldown: float = 1.0
## Reichweite des Primärbereichs (Kegel/Kreis) in px.
@export var attack_range: float = 130.0
## Halber Öffnungswinkel in Radiant (nur Kegel-Waffen).
@export var half_arc: float = 0.7
## Nahbereich-Kreis um den Spieler (fängt Kleber ab).
@export var aoe_radius: float = 80.0
## Kettenschaden: Anzahl zusätzlicher Sprung-Ziele (Donnerkeil = 3).
@export var chain_count: int = 0
## Blutung: DoT in % des Trefferschadens pro Sekunde (Sichel).
@export var bleed_pct: float = 0.0
@export var max_level: int = 8
## Evolutions-Ziel (leer = keine Evolution).
@export var evolution_id: StringName
## Benötigtes Passiv für die Evolution (Lv. 5, Waffen-Dokument §1).
@export var required_passive_id: StringName


## DPS nach Balancing §8: base_damage × 1.30^(level-1).
func damage_for_level(level: int) -> float:
	return base_damage * pow(1.30, float(level - 1))
