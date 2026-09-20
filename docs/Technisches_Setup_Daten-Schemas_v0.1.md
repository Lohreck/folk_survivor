# Technisches Setup & Daten-Schemas
### Ergänzung zum GDD "Survivor-Like Mobile" v0.1

Hinweis: Konkretisiert `Technisches_Konzept_Godot_v0.1.md` für den Projektstart. Alle Zahlen sind **Startwerte** und gehören ins Tuning-Register von `Playtesting_Tuning_Plan_v0.1.md`, sobald das Projekt läuft. Ziel: Meilenstein 0 und 1 ohne weitere Vorab-Entscheidungen umsetzbar machen.

---

## 1. Projekt-Grundgerüst

### 1.1 Engine-Version & Renderer
- **Godot 4.x, Stable** – exakte Version bei Projektstart **fixieren** und im Repo dokumentieren (`project.godot` mitcommitten). Kein Engine-Update mitten in der Produktion ohne Test.
- Renderer: **Mobile** (`rendering/renderer/rendering_method = "mobile"`)
- 2D-Physik-Ticks: **60/s** (`physics/common/physics_ticks_per_second = 60`)
- Gravitation: **0** (`physics/2d/default_gravity = 0`) – Top-down
- 2D-MSAA: **aus** (Performance)
- Texturfilter: **Nearest** (`rendering/textures/canvas_textures/default_texture_filter = Nearest`) – Pixelart-Stil

### 1.2 Android-/Build-Konfiguration
| Feld | Wert (Startwert) |
|---|---|
| App-Name | Nav' – Slawische Horde |
| Android-Package | `com.<studio>.navhorde` *(Platzhalter – vor erstem Build festlegen)* |
| Version Name / Code | `0.1.0` / `1` |
| Min. Android | API 24 (Android 7.0) |
| Target | jeweils aktuelles Play-Store-Ziel |
| Build-Format | **AAB** (Play Store), APK nur für interne Tests |
| Keystore | **niemals** committen – lokal/CI-Secret; Passwörter außerhalb des Repos |

### 1.3 Auflösung, Viewport & Orientierung
- Orientierung: **landscape**
- Basis-Auflösung: **1280×720**
- Stretch Mode: **`canvas_items`**
- Stretch Aspect: **`expand`** → Geräte mit 20:9 sehen seitlich mehr (Gameplay-Vorteil), kein Letterboxing
- UI wird an **Safe Areas** verankert (Notch/Punch-Hole), HUD bleibt in Daumen-Reichweite (siehe UI-Dokument)

### 1.4 Git & Assets
- Repo-Struktur gemäß Technisches Konzept §2 (`autoload/`, `scenes/`, `resources/`, `assets/`, `addons/`)
- `.gitignore`: `.godot/`, `export/`, `*.translation`, `.import/`
- **Git LFS** für Binärassets: `*.png`, `*.wav`, `*.ogg`, `*.ttf`, `*.aseprite` (siehe `.gitattributes`)
- Szenen-/Resource-Merge-Konflikte: Regel „eine Szene, eine Person" + `.tscn`/`.tres` klein halten (siehe Technisches §11)

---

## 2. Spielwelt & Kamera

| Parameter | Startwert | Anmerkung |
|---|---|---|
| Arena-Größe | **4096 × 4096** Welt-Pixel | pro Region eigene Map, gleiche Grundgröße |
| Kamera | `Camera2D`, folgt Spieler zentriert | kein Zoom, kein Shake im Basis-Setup |
| Kamera-Clamping | Position auf Arena-Grenzen begrenzt | verhindert Blick „hinter" die Map |
| Off-Screen-Spawn | Ring um Spieler bei `max(halbe Viewport-Diagonale + 64, 480)` px | Spawns nur innerhalb der Arena; nahe Rand auf verfügbarem Bogen |
| Despawn | Gegner außerhalb `2× Spawn-Radius` werden zurück in den Pool gegeben | verhindert „verlorene" Gegner |
| Boden | `TileMapLayer` + prozedurale Hazard-Overlays | Hazards (Schlamm, Eis) als Area2D-Trigger |

**Hinweis:** Arena-Größe 4096 entspricht bei Spielertempo 200 px/s ca. 20 s Durchquerung – groß genug für Ausweich-Räume, klein genug, um Gegner nicht zu verlieren. Tunebar.

---

## 3. Basis-Zahlen

### 3.1 Spieler
| Parameter | Wert |
|---|---|
| Basis-Geschwindigkeit | **200 px/s** (Multiplikatoren je Charakter: 0.8–1.3) |
| Kollisionsradius (Body) | 14 px |
| Magnet-/Pickup-Radius (Basis) | 64 px |
| Kontakt-Schadens-Cooldown | 0.5 s (Invulnerabilität nach Treffer) |
| XP-Gem-Anziehung | 300 px/s innerhalb des Magnet-Radius |

### 3.2 Gegner (abgeleitet aus Balancing-Tempo-Multiplikatoren)
| Gegner | Tempo | effektive px/s | Kollisionsradius |
|---|---|---|---|
| Kikimora | 1.15 | 230 | 12 |
| Domovoi | 0.70 | 140 | 16 |
| Aitvaras | 1.00 | 200 | 14 |
| Upyr | 1.25 | 250 | 14 |
| Vodyanoy | 0.65 | 130 | 18 |
| Velnias-Diener | 0.80 | 160 | 16 |
| Žaltys | 0.85 | 170 | 20 |
| Mini-Boss | – | 120–180 | 40 |
| Boss | – | 100–160 | 64–96 |

### 3.3 Waffen (Auto-Attack, Basiswerte Stufe 1)
| Waffe | Typ | Schaden | Cooldown | Reichweite | Projektil-Tempo | Besonderheit |
|---|---|---|---|---|---|---|
| Axt | Nahkampf-Bogen | 10 | 0.8 s | 80 px, 120° | – | Standard |
| Sichel | Schneller Nahkampf | 6 | 0.5 s | 70 px, 90° | – | Blutung 3 s |
| Eisernes Hufeisen | Wurf/Bumerang | 14 | 1.2 s | 260 px | 400 px/s | kehrt zurück |
| Weihwasser-Phiole | Fläche | 16 | 1.5 s | Radius 100 px | – | trifft mehrere |
| Donnerkeil | Kette | 18 | 1.6 s | 220 px | – | springt auf 3 Gegner |

→ Start-DPS je Waffe ≈ 11–13, passt zu den Charakter-Startwerten (10–16). Level-Skalierung: **×1.30 pro Waffe-Level** (Balancing §8).

**Auto-Ziel-Logik:** nächstgelegener Gegner innerhalb der Waffenreichweite; Gleichstand → Winkel zur Blickrichtung.

### 3.4 Pickups
| Element | Regel |
|---|---|
| XP-Gem | fällt beim Kill, wird per Magnet eingesammelt |
| Gold | wird **direkt beim Kill gutgeschrieben** (kein Pickup) – vereinfacht, da fractional |
| Truhen | Area2D-Trigger, öffnen bei Kontakt |

---

## 4. Kollision & Physik (Layer-Matrix)

| Layer | Inhalt |
|---|---|
| 1 | Spieler |
| 2 | Gegner |
| 3 | Spieler-Projektile |
| 4 | Gegner-Projektile |
| 5 | Pickups (XP-Gems, Truhen) |
| 6 | Hazards / Trigger |
| 7 | Arena-Grenzen |

**Wichtige Performance-Regel:** Gegner **kollidieren nicht untereinander** (keine Enemy-Enemy-Physik) – sie dürfen sich überlappen. Kontaktschaden läuft über `Area2D` am Spieler. Das ist entscheidend, damit 85 Gegner auf Mobile bezahlbar bleiben.

- Spieler: `CharacterBody2D` (Bewegung), Child-`Area2D` für Kontaktschaden & Pickup-Radius
- Gegner: `CharacterBody2D`/`Area2D` (Bewegung ohne Kollision gegen Layer 2)
- Projektile: `Area2D`, treffen Layer 2 (Spieler) bzw. 1 (Gegner)

---

## 5. Object-Pool-Größen (Startwerte)

| Pool | Größe | Begründung |
|---|---|---|
| Kikimora | 100 | Schwarm-Haupttyp |
| Domovoi | 40 | |
| Aitvaras | 40 | |
| Upyr | 40 | |
| Vodyanoy | 30 | |
| Velnias-Diener | 30 | |
| Žaltys | 20 | Elite |
| Spieler-Projektile | 200 | |
| Gegner-Projektile | 150 | Balancing §9 |
| XP-Gems | 200 | |
| Summe Gegner | **~300** | harte Obergrenze aktiv: 85 |

Pool wird pro Region vorab instanziiert; zwischen `active`/`inactive` umgeschaltet (`visible=false`, Kollision aus, Position außerhalb). Siehe Technisches §3.

---

## 6. Daten-Schemas (Custom Resources)

Alle Werte als `.tres`, nicht im Code. Beispielklassen (Felder sind der verbindliche Stand; Erweiterungen später möglich):

```gdscript
# enemy_data.gd
class_name EnemyData extends Resource
enum Role { SWARM, RANGED, FLYER, ELITE, MINIBOSS, BOSS }

@export var id: StringName
@export var display_name: String
@export var role: Role = Role.SWARM
@export var scene: PackedScene
@export var base_hp: float
@export var base_damage: float
@export var move_speed: float          # px/s
@export var contact_radius: float
@export var xp_value: int
@export var gold_value: float          # fractional
@export var spawn_weight: float
@export var native_region: int
@export var is_flying: bool = false
@export var has_shield: bool = false
@export var lifesteal: float = 0.0
@export var attack_range: float = 0.0       # >0 = Fernkampf
@export var attack_cooldown: float = 0.0
@export var projectile_scene: PackedScene
@export var signature_sfx: AudioStream
```

```gdscript
# weapon_data.gd
class_name WeaponData extends Resource
@export var id: StringName
@export var display_name: String
@export var scene: PackedScene
@export var base_damage: float
@export var cooldown: float
@export var range: float
@export var arc_degrees: float = 0.0
@export var aoe_radius: float = 0.0
@export var projectile_speed: float = 0.0
@export var pierce: int = 0
@export var chain_count: int = 0
@export var max_level: int = 8
@export var evolution_id: StringName          # Ziel-Evolution (leer = keine)
@export var required_passive_id: StringName   # benötigtes Passiv
@export var sfx: AudioStream
```

```gdscript
# passive_data.gd
class_name PassiveData extends Resource
@export var id: StringName
@export var display_name: String
@export var stat: StringName                 # z. B. "max_hp", "area_damage", "crit"
@export var value_per_level: PackedFloat32Array  # Länge 5
@export var max_level: int = 5
@export var evolution_weapon_id: StringName
```

```gdscript
# character_data.gd
class_name CharacterData extends Resource
enum Unlock { START, GOLD, PROGRESS }
@export var id: StringName
@export var display_name: String
@export var sprite: Texture2D
@export var base_hp: float
@export var speed_multiplier: float
@export var start_weapon_id: StringName
@export var passive_id: StringName
@export var passive_value: float
@export var unlock_type: Unlock = Unlock.PROGRESS
@export var unlock_cost: int = 0
@export var unlock_region: int = 0
@export var unlock_boss_id: StringName
```

```gdscript
# region_data.gd
class_name RegionData extends Resource
@export var id: StringName
@export var display_name: String
@export var map_scene: PackedScene
@export var hp_multiplier: float
@export var damage_multiplier: float
@export var spawn_basis: float
@export var music_layers: Array[AudioStream]
@export var enemy_spawn_table: Array[EnemySpawnEntry]   # EnemyData + weight
@export var mini_boss_id: StringName
@export var main_boss_id: StringName
@export var unlock_condition: StringName
```

```gdscript
# evolution_data.gd / double_evolution_data.gd
class_name EvolutionData extends Resource
@export var id: StringName
@export var display_name: String
@export var base_weapon_id: StringName
@export var required_passive_id: StringName
@export var result_scene: PackedScene
@export var structural_effect: String

class_name DoubleEvolutionData extends Resource
@export var id: StringName
@export var display_name: String
@export var weapon_a_id: StringName
@export var weapon_b_id: StringName
@export var required_item_id: StringName      # Ahnen-Item
@export var result_scene: PackedScene
@export var structural_effect: String
```

```gdscript
# save_data.gd  (JSON, siehe Technisches §6)
{
  "save_version": 1,
  "gold": 0,
  "bernstein": 0,
  "talents": { "start_hp": 0, "gold_rate": 0, "rerolls": 0 },
  "unlocked_characters": ["holzaeller", "soldat"],
  "unlocked_regions": [1],
  "bosses_defeated": []
}
```

---

## 7. Mechanik-Timing (Run-Zeitleiste)

**Interpretation der 12-Minuten-Angabe:** Wellenphase 0–10 Min., danach Boss. Ein gewonnener Run dauert typisch **11–13 Min.** (12 = Nominalwert). Das präzisiert die bisher vage „Zeitgrenze".

| Zeit | Ereignis |
|---|---|
| 0:00 | Run-Start, Sound-Intensität 1 |
| 3:00 | Sound 2, Dichte steigt |
| 5:00 | Erster Elite-Spawn |
| 6:00 | **Scripted Mini-Boss** (außer Region 1) |
| 6:00–8:00 | Sound 3 |
| 9:00 | Spawn-Rate eingefroren, Sound 4 |
| **10:00** | Spawn-Stop + **Hauptboss** erscheint |
| Boss-Sieg | Run-Ende (Sieg) |

**Region-spezifische Phasen:**
| Region | Phase | Startwert |
|---|---|---|
| 2 | „Mittagszeit" | Fenster 5:30–7:00; Poludnitsa-Spawn bei 6:00 |
| 4 | Periodische Nacht (Wellenphase) | alle 90 s für 20 s, 1 s Vignetten-Vorwarnung |
| 4 | Chernobog Tag/Nacht | Tag 25 s → Nacht 15 s, wiederholend; Phasenwechsel zusätzlich an HP-Marken (66 % / 33 %) |

Alle Zeiten sind Tunable und werden im Playtesting-Plan (§5.1) geführt.

---

## 8. Audio-Bus-Konfiguration (aus Sound-Dokument §6)

```
Master
├── Music        (Layer_Basis / _Rhythmus / _Melodie / _Intensitaet)
├── SFX_Priority (nie geduckt)
├── SFX_Enemies  (Ducking ab 40 Gegner-Sounds)
└── SFX_UI
```
- Musik-Layer werden synchron gestartet, Lautstärke per `volume_db`-Crossfade (2–3 s) über den `SpawnDirector` gesteuert.

---

## 9. Definition of Ready

**Meilenstein 0 startklar, wenn:**
- [ ] Repo + `.gitignore` + LFS eingerichtet, Engine-Version gepinnt
- [ ] Godot-Projekt mit Mobile-Renderer, Landscape, 1280×720 / expand
- [ ] Testgerät (Mittelklasse-Android) verfügbar

**Meilenstein 1 startklar, wenn zusätzlich:**
- [ ] Resource-Klassen aus §6 angelegt und kompilierbar
- [ ] Arena/Kamera/Off-Screen-Spawn aus §2 implementiert
- [ ] Kollisions-Layer-Matrix aus §4 gesetzt
- [ ] Platzhalter-Assets + Ordnerstruktur stehen

---

## 10. Offene Punkte
- **Android-Package-ID** (`com.<studio>.navhorde`) und Studio-Name final festlegen
- Genaue Engine-Version bei Start eintragen
- Ob Regionen unterschiedliche Arena-Größen brauchen (aktuell einheitlich 4096²)
- Ob Gold doch als Pickup statt Direktgutschrift kommen soll (Feedback-Gefühl)
- Feinwerte (Tempo, Cooldowns, Pool-Größen) → `Playtesting_Tuning_Plan_v0.1.md`
