# Technisches Umsetzungskonzept – Godot
### Ergänzung zum GDD "Survivor-Like Mobile" v0.1

Hinweis: Grobkonzept für den Projektstart, kein vollständiges Architektur-Dokument. Ziel ist eine solide, erweiterbare Basis, die die Kernanforderungen (viele gleichzeitige Gegner, Mobile-Performance, Meta-Progression) von Anfang an mitdenkt.

---

## 1. Engine-Version & Grundsetup

- **Godot 4.x** (aktuelle Stable-Version), 2D-Workflow
- **Renderer:** Mobile-Renderer explizit wählen (Project Settings → Rendering → Renderer → "Mobile"), nicht den Forward+-Desktop-Renderer – deutlich bessere Performance auf Android-Mittelklasse-Geräten
- **Physik:** 2D-Physik nur wo nötig (Kollisionen Spieler/Gegner/Projektile), keine komplexen Physik-Interaktionen – spart Rechenzeit

---

## 2. Projektstruktur (Vorschlag)

```
res://
├── autoload/          # Singletons (siehe Punkt 4)
├── scenes/
│   ├── player/
│   ├── enemies/
│   │   ├── base_enemy.tscn
│   │   └── [gegnertyp].tscn
│   ├── weapons/
│   ├── bosses/
│   ├── ui/
│   │   ├── hud/
│   │   ├── level_up_screen/
│   │   └── meta_menu/
│   ├── regions/       # Eine Szene pro Region-Map
│   └── main_menu.tscn
├── resources/          # .tres-Dateien für Daten (siehe Punkt 5)
│   ├── enemies/
│   ├── weapons/
│   ├── characters/
│   └── regions/
├── scripts/            # Falls nicht direkt an Szenen gehängt
└── assets/
    ├── sprites/
    ├── audio/
    └── fonts/
```

---

## 3. Kernsystem: Object Pooling (kritisch für Performance)

Bei bis zu 85 gleichzeitigen Gegnern (siehe Balancing-Dokument) ist **kein** `instantiate()`/`queue_free()` pro Spawn/Tod vertretbar – das erzeugt Garbage-Collection-Spitzen, die auf Mobile zu Frame-Drops führen.

**Ansatz:**
- Pro Gegnertyp ein Pool aus vorinstanziierten Node-Instanzen (z. B. 100 Kikimora-Instanzen beim Region-Start), die zwischen `active`/`inactive` umgeschaltet werden (`visible = false`, Kollision deaktiviert, Position außerhalb des Screens) statt gelöscht zu werden
- Gleiches Prinzip für Projektile (Waffen-Treffer, Fernkampf-Gegner)
- Godot-natives Werkzeug: `Node.set_process(false)` + `visible = false` reicht oft aus; bei Bedarf ein eigenes `ObjectPool`-Autoload mit `get_instance(type)` / `return_instance(instance)`-API

---

## 4. Autoload-Singletons (globaler Zustand)

| Singleton | Zuständigkeit |
|---|---|
| `GameState` | Aktueller Run-Zustand (Zeit, gewählter Charakter, aktive Waffen/Passivs, Gold im Run) |
| `MetaProgress` | Persistenter Fortschritt (Talentbaum-Stufen, freigeschaltete Charaktere/Regionen, Gold/Bernstein-Bestand) |
| `EnemyPoolManager` | Object-Pooling-Logik (siehe Punkt 3) |
| `SpawnDirector` | Steuert Spawn-Kurven pro Minute/Region (liest Werte aus den Balancing-Resources) |
| `AudioManager` | Zentrale Musik-/SFX-Steuerung, inkl. Lautstärke-Settings |
| `SaveManager` | Laden/Speichern von `MetaProgress` (siehe Punkt 6) |

**Wichtig:** `GameState` wird bei Run-Ende bewusst verworfen/zurückgesetzt, nur `MetaProgress` ist dauerhaft – klare Trennung zwischen "Run-Daten" und "Meta-Daten" vermeidet Bugs durch versehentlich persistierte Run-Werte.

---

## 5. Daten-getriebenes Design mit Godot Resources

Statt Gegner-/Waffen-/Charakterwerte im Code zu hartcodieren: **Custom Resources** (`.tres`-Dateien) nutzen, z. B.:

```gdscript
# enemy_data.gd
class_name EnemyData
extends Resource

@export var display_name: String
@export var base_hp: float
@export var base_damage: float
@export var move_speed: float
@export var scene: PackedScene
@export var spawn_weight: float
```

**Vorteil:** Die Werte aus dem Balancing-Dokument (Punkt 3 dort) lassen sich 1:1 als `.tres`-Dateien im Godot-Editor pflegen, ohne Code anzufassen – auch für Nicht-Programmierer im Team später editierbar. Gleiches Prinzip für `WeaponData`, `CharacterData`, `RegionData`.

---

## 6. Speichersystem (lokal + Cloud-Vorbereitung)

- **Lokal:** `MetaProgress` als JSON via `FileAccess` in `user://save_data.json` – einfach, robust, gut debugbar
- **Cloud-Sync (später):** Google Play Games Services (Saved Games API) einplanen, aber **nicht** für den ersten Prototyp – lokal speichern reicht für Playtesting völlig aus
- **Wichtig von Anfang an:** Save-Datei-Versionierung (`"save_version": 1`) einbauen, damit spätere Struktur-Änderungen nicht bestehende Spielstände zerstören

---

## 7. Mobile-spezifische Eingabe

- Virtueller Joystick: eigenes UI-Control-Node (Touch-Events über `_input()` bzw. `InputEventScreenTouch`/`InputEventScreenDrag`), linke untere Bildschirmhälfte
- Kein manuelles Zielen nötig (Auto-Attack, siehe GDD) – reduziert Touch-Steuerungskomplexität erheblich
- `Project Settings → Display → Window → Handheld → Orientation` auf `portrait` oder `landscape` festlegen, je nach finaler Entscheidung (Empfehlung: **landscape**, da Genre-üblich und mehr Sichtfeld für Horde-Übersicht bietet)

---

## 8. Spawn-System (Umsetzung der Balancing-Kurven)

`SpawnDirector`-Autoload liest pro Frame/Sekunde:
1. Aktuelle Run-Minute → berechnet HP-/Schadens-Multiplikator (Formel aus Balancing-Dokument Punkt 4)
2. Aktuelle Region → wendet Regionen-Multiplikator an (Balancing-Dokument Punkt 5)
3. Spawn-Rate → holt passende Gegner aus `EnemyPoolManager`, gewichtet nach `spawn_weight` aus den jeweiligen `EnemyData`-Resources
4. Deckel-Logik (ab Minute 10 eingefroren) direkt hier zentral implementiert – ein einziger Ort für diese Regel, kein Duplizieren der Logik in einzelnen Gegner-Skripten

---

## 9. Werbe-/Monetarisierungs-Integration (technisch)

- **AdMob** (Google) ist der naheliegende Standard für Android – Plugin z. B. über die Community-Erweiterung "Poing Studios AdMob Plugin" oder offizielle Godot-Android-Plugin-Struktur
- Rewarded-Ad-Callback muss sauber mit `GameState` verzahnt sein (z. B. "Zweite Chance"-Ad triggert einen `revive_player()`-Aufruf im `GameState`, nicht direkt in der UI-Szene) – hält die Ad-Logik von der Spiellogik entkoppelt

---

## 10. Empfohlene Entwicklungsreihenfolge (technischer Prototyp)

1. Object-Pooling-Grundgerüst + ein einzelner Gegnertyp (Kikimora) mit bis zu 85 gleichzeitigen Instanzen (Testpuffer 100) → **Performance-Test auf echtem Mittelklasse-Android-Gerät**, bevor mehr Inhalt gebaut wird
2. Spieler-Bewegung (virtueller Joystick) + eine Waffe (Auto-Attack) + Level-Up-Screen-Grundgerüst
3. `SpawnDirector` mit den Balancing-Werten aus Region 1
4. Erste Meta-Progression-Schleife (Gold sammeln → Talentbaum-Stufe kaufen → sichtbarer Effekt im nächsten Run)
5. Erst danach: weitere Gegnertypen, Waffen, Bosse, Regionen inhaltlich auffüllen

**Begründung für diese Reihenfolge:** Schritt 1 ist das größte technische Risiko (Performance mit vielen Gegnern auf Mobile) – sollte so früh wie möglich validiert werden, bevor Zeit in Inhalt investiert wird, der bei Performance-Problemen ohnehin überarbeitet werden müsste.

---

## 11. Offene Punkte
- Konkrete Wahl des AdMob-Plugins/Integrationswegs (abhängig vom aktuellen Stand der Godot-Android-Plugin-Landschaft zum Entwicklungszeitpunkt)
- Ob React/Web-Export für einen browserbasierten Prototyp zusätzlich sinnvoll ist (schnelleres Testen ohne Android-Build-Zyklus)
- Team-Setup: falls mehrere Personen am Projekt arbeiten, Versionskontrolle-Workflow für `.tscn`/`.tres`-Dateien festlegen (Godot-Szenen sind textbasiert und Git-freundlich, aber Merge-Konflikte bei gleichzeitiger Szenen-Bearbeitung bleiben ein bekanntes Risiko)

→ Technische Restentscheidungen siehe `Playtesting_Tuning_Plan_v0.1.md` (Abschnitt 8); benötigte Telemetrie-Events siehe dort Abschnitt 4.
→ Konkrete Projektkonfiguration, Daten-Schemas und Basis-Zahlen: `Technisches_Setup_Daten-Schemas_v0.1.md`.
