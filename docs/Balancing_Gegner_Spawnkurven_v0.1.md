# Balancing: Gegnerwerte & Spawn-Kurven
### Ergänzung zum GDD "Survivor-Like Mobile" v0.1

Hinweis: **Grobgerüst**, kein finales Balancing. Ziel sind plausible, testbare Startwerte, die zu den bereits festgelegten Systemen (Object Pooling, `SpawnDirector`, adaptive Musik, Gold-Kurven) passen. Alle Formeln sind so aufgebaut, dass sie 1:1 als Werte in `EnemyData`-/`RegionData`-Resources bzw. als zentrale Funktionen im `SpawnDirector` abgebildet werden können (siehe Technisches Konzept, Punkte 5 & 8).

---

## 1. Grundprinzip & Zielwerte

Das Balancing folgt drei getrennten Skalierungs-Achsen, die sich multiplizieren:

| Achse | Steuert | Wo umgesetzt |
|---|---|---|
| **Zeit im Run** | HP & Schaden der Gegner steigen über die Run-Dauer | `SpawnDirector`, pro Sekunde |
| **Region** | Grundschwierigkeit der Map (HP/Schaden aller Gegner) | `RegionData`-Resource |
| **Gegnertyp** | Intrinsische Basiswerte (HP, Tempo, XP, Gold) | `EnemyData`-Resource |

**Grundregeln:**
- **Kein Pay-to-Win-Risiko im Balancing:** Schwierigkeit skaliert nur über Zeit/Region, nie über Zufall, der einen Run unspielbar macht.
- **Lesbarkeit vor Zahlen:** Bei bis zu 85 Gegnern gleichzeitig muss jeder Gegnertyp eine klar erkennbare Rolle haben (Schwarm, Fernkampf, Elite) – Werte allein reichen nicht, die Silhouette (siehe Barrierefreiheits-Dokument) trägt die Unterscheidung.
- **Weiches Ende:** Die Spawn-Rate wird ab Minute 9 eingefroren, die Stat-Skalierung ab Minute 10; bei Minute 10 stoppt das Spawnen und der Hauptboss erscheint (siehe Punkt 3 & 4).

**Ziel-Gegnerzahl (vereinheitlicht):**
| Wert | Zahl | Bedeutung |
|---|---|---|
| Harte Obergrenze aktiver Gegner | **85** | `EnemyPoolManager`-Deckel pro Region |
| Ziel-Durchschnitt mittlerer Run | **45–60** | anvisierte Gleichzeitigkeit ab Minute 5 |
| Performance-Testwert (Meilenstein 0) | **100** | Sicherheitspuffer, kein Dauerzustand |
| Marketing-Aussage Store | "85+" | entspricht der harten Obergrenze aktiver Gegner |

---

## 2. Gegner-Basiswerte

**Referenz:** Alle HP-/Schadenswerte sind auf **Region-1-/Minute-1-Niveau normalisiert** – die Regionen- und Zeit-Multiplikatoren (Punkte 4 & 5) kommen erst zur Laufzeit darauf. Dadurch bleiben die `EnemyData`-Werte stabil und Balancing-Änderungen passieren an einer Stelle.

**Gold/XP sind native Endwerte** (nicht skaliert). Gold ist bewusst **fractional** – bei tausenden Kills pro Run (siehe Punkt 3.1.1) ergibt sich der Run-Gewinn erst aus der Summe. Die Ø-Werte pro Region sind mit dem Wirtschafts-Dokument abgestimmt.

| Gegner | Region | Rolle | Basis-HP | Schaden | Tempo (× Spieler) | XP | Gold |
|---|---|---|---|---|---|---|---|
| Kikimora | 1 | Schwarm | 8 | 5 | 1.15 | 2 | 0.06 |
| Domovoi (verdorben) | 1 | Fernkampf | 22 | 7 | 0.45 | 3 | 0.14 |
| Aitvaras | 1 (vereinzelt) / 2 | Flieger | 15 | 6 | 0.65 | 2 | 0.10 |
| Upyr | 2 | Verfolger / Lifesteal | 30 | 12 | 1.25 | 3 | 0.13 |
| Vodyanoy | 2 | Sog / Nahkampf | 45 | 15 | 0.65 | 3 | 0.16 |
| Velnias-Diener | 3 | Schild / Nahkampf | 60 | 14 | 0.80 | 3 | 0.30 |
| Žaltys (verflucht) | 4 | Elite / Peitsche | 90 | 18 | 0.85 | 4 | 0.30 |

**XP steigt absichtlich nur schwach mit der Region (1–4 pro Gegner):** Die Kill-Zahl verdoppelt sich bereits von Region 1 zu Region 4 (Punkt 3.1.1). Würde zusätzlich der XP-Wert pro Gegner stark steigen, explodiert die Level-Kurve in der Endregion (siehe Punkt 7).

**Hinweis zur Konsistenz:** Das Meilenstein-Dokument nennt Upyr unter Region 1; das Regionen-Dokument führt ihn unter Region 2. Dieses Dokument folgt dem **Regionen-Dokument** (Upyr = Region 2) – siehe Abstimmungspunkt 10.

**Tempo-Referenz:** Spieler-Basistempo = 1.0× (Soldat = 1.0, Holzfäller = 0.8, Waisenkind = 1.3 laut Charaktere-Dokument). Gegner-Tempo ist relativ dazu angegeben, nicht in absoluten Pixel/s.

---

## 3. Spawn-Kurven & Gegner-Mix

### 3.1 Spawn-Rate (Basis pro Region)

```
Spawn_Rate(Minute t) = Region_Spawn_Basis × (1 + 0.30 × (t - 1))
```
→ **eingefroren ab Minute 9** (Wert von Minute 9 gilt für 9–10 weiter; bei Minute 10 stoppt das Spawnen für den Boss). Grund: Der Deckel aus Technisches Konzept Punkt 8 wird so erreicht, bevor der Boss kommt.

| Region | Spawn-Basis (Minute 1) | Rate bei Minute 9 (eingefroren) |
|---|---|---|
| 1. Dammerwald | 1.5 / s | 5.1 / s |
| 2. Sumpfmoor | 2.0 / s | 6.8 / s |
| 3. Dorf der Vergessenen | 2.5 / s | 8.5 / s |
| 4. Reich von Nav' | 3.0 / s | 10.2 / s |

### 3.1.1 Erwartete Spawns & Kills pro Run (12 Min.)

Abgeleitet aus den Spawn-Raten (Punkt 3.1) × Ø-Multiplikator **2.5** (Minuten 1–9 wachsend, 10–12 eingefroren) × 720 s, davon **~70 % On-Screen-Kills** (Rest despawnen oder bleiben stehen). Diese Werte sind die Grundlage der Gold-Ökonomie im Wirtschafts-Dokument:

| Region | Ø Spawns/Run | Ø Kills/Run (~70 %) |
|---|---|---|
| 1. Dammerwald | ~2.700 | ~1.900 |
| 2. Sumpfmoor | ~3.600 | ~2.500 |
| 3. Dorf der Vergessenen | ~4.500 | ~3.100 |
| 4. Reich von Nav' | ~5.400 | ~3.800 |

**Genre-Kontext:** Tausende Kills pro Run sind der Standard in Bullet-Heaven-Titeln (Vampire Survivors: 3.000–10.000+ in einem 30-Min-Run). Kleine Ø-Gold-Werte pro Kill sind die logische Konsequenz – wer beides gleichzeitig hoch ansetzt, sprengt die Run-Ökonomie.

### 3.2 Aktive-Gegner-Deckel (Rampe)

```
Max_Active(Minute t) = min(85, 15 + 8 × t)
```
→ Minute 1: 23 · Minute 5: 55 · Minute 9+: **85 (hart)**. Verhindert einen Overload in den ersten Minuten, in denen der Spieler noch kaum DPS hat.

### 3.3 Gegner-Mix pro Region (Gewichtung)

Die `spawn_weight`-Werte der `EnemyData`-Resources werden pro Region verschoben, sodass sich der Mix über die Region verändert (nicht die Einzelwerte):

| Region | Standard-Mix | Ab Minute 5 zusätzlich | Ab Minute 9 zusätzlich |
|---|---|---|---|
| 1 | Kikimora 70% / Domovoi 20% / Aitvaras 10% | Erste Elite (Aitvaras-Gruppe) | Domovoi-Anteil ↑ |
| 2 | Upyr 35% / Aitvaras 25% / Domovoi 20% / Vodyanoy 20% | Vodyanoy ↑ | Rusalka-Spawn (wiederkehrend) |
| 3 | Domovoi 40% / Kikimora 35% / Velnias-Diener 25% | Velnias ↑ | Kikimora-Dichte ↑ |
| 4 | Elite-Mix aus allen Regionen + Žaltys | Žaltys ↑ | gemischte Elite-Wellen |

### 3.4 Feste Ereignisse pro Run

| Zeit | Ereignis |
|---|---|
| 0:00–2:00 | Ruhige Aufbauphase, wenig Gegner (Sound-Intensität 1) |
| 3:00–5:00 | Dichte steigt (Sound 2) |
| 5:00 | Erster Elite-Spawn |
| 6:00 | Scripted Mini-Boss erscheint (außer Region 1) |
| 6:00–8:00 | Dichte hoch (Sound 3) |
| 9:00 | Spawn-Rate eingefroren (Sound 4) |
| 10:00 | Spawn-Stop + Hauptboss erscheint; Run endet mit Boss-Sieg (Gesamtdauer ~11–13 Min.) |

**Ausnahme Region 1:** kein Mini-Boss – Region 1 ist bewusst die Tutorial-Region (siehe Regionen-Dokument). Der Mini-Boss-Slot bei ~Minute 6 bleibt dort leer; der erste Mini-Boss ist Poludnitsa in Region 2.

---

## 4. Zeit-Skalierung im Run

Wird vom `SpawnDirector` pro Sekunde aus der aktuellen Run-Minute berechnet (siehe Technisches Konzept Punkt 8.1). Statt einer glatten Exponentialkurve nutzt das Spiel eine **stückweise Kurve mit multiplikativen Spikes** an festen Marken – näher am Genre-Standard (spürbare Schwierigkeitssprünge statt gleichförmigem Anstieg):

```
Basiswachstum:         ×1.10 pro Minute
Multiplikative Spikes: Minute 3 ×1.08 · Minute 5 ×1.10 · Minute 7 ×1.10 · Minute 10 ×1.15
Schaden:               1 + 0.03 × (t - 1)
Eingefroren ab Minute 10 (Werte von Minute 10 gelten für 10–12)
```

| Minute | HP-Multiplikator | Schaden-Multiplikator | Auslöser des Spikes |
|---|---|---|---|
| 1 | 1.00 | 1.00 | – |
| 2 | 1.10 | 1.03 | – |
| 3 | 1.31 | 1.06 | kleiner Spike |
| 4 | 1.44 | 1.09 | – |
| 5 | 1.74 | 1.12 | erste Elites |
| 6 | 1.91 | 1.15 | – |
| 7 | 2.32 | 1.18 | Spike |
| 8 | 2.55 | 1.21 | – |
| 9 | 2.80 | 1.24 | – |
| 10–12 | **3.54 (eingefroren)** | **1.27 (eingefroren)** | großer Spike + Spawn-Deckel |

**Warum stückweise:** Die Spikes fallen mit den Ereignissen aus Punkt 3.4 zusammen (erste Elites bei Minute 5, Spawn-Deckel bei Minute 10). Spieler erleben so klar getrennte Eskalationsstufen. **Warum Schaden nur linear:** verhindert One-Shots ab Minute 8 – auf Mobile (geringe Reaktionsfläche) unfair.

---

## 5. Regionen-Multiplikator

Angewandt auf **alle** Gegner der Region, inklusive der in Region 4 gemischten Elite-Spawns aus früheren Regionen (siehe Regionen-Dokument):

| Region | HP-Multiplikator | Schaden-Multiplikator |
|---|---|---|
| 1. Dammerwald | ×1.0 | ×1.0 |
| 2. Sumpfmoor | ×1.5 | ×1.25 |
| 3. Dorf der Vergessenen | ×2.2 | ×1.55 |
| 4. Reich von Nav' | ×3.2 | ×1.9 |

**Gesamtformel (Kern für den `SpawnDirector`):**
```
HP_effektiv  = Basis_HP  × Region_HP_Mult  × HP_Multiplikator(Minute)
Schaden_effektiv = Basis_Schaden × Region_Dmg_Mult × Schaden_Multiplikator(Minute)
```

**Beispiel:** Kikimora (Basis-HP 8) in Region 2, Minute 9:
`8 × 1.5 × 2.80 ≈ 34 HP` – stirbt in wenigen Treffern, bleibt aber als Schwarm bedrohlich durch Masse.

**Beispiel:** Žaltys (Basis-HP 90) in Region 4, Minute 12:
`90 × 3.2 × 3.54 ≈ 1.020 HP` – klar als Elite spürbar, ohne bullet-sponge zu werden.

---

## 6. Elite-, Mini-Boss- & Boss-Werte (TTK-basiert)

**Leitgröße ist die Time-to-Kill (TTK), nicht die absolute HP.** HP wird aus `erwarteter Spieler-DPS × Ziel-TTK` hergeleitet – dadurch bleibt das Balancing stabil, wenn sich Waffen-/DPS-Werte ändern. Genre-übliche TTK-Ziele:

| Gegnertyp | Ziel-TTK |
|---|---|
| Trash/Schwarm | 0,3–0,6 s |
| Elite | 3–8 s |
| Mini-Boss | 20–45 s |
| Hauptboss | 45–90 s |

**Angenommene Spieler-DPS-Kurve (Design-Ziel):**
| Run-Minute | Erwartete DPS |
|---|---|
| 1 | ~12 |
| 3 | ~30 |
| 5 | ~60 |
| 6 | ~85 |
| 8 | ~160 |
| 9 | ~220 |
| 12 | ~380–420 |

**Mini-Bosse & Bosse:**
| Boss | Region | Typ | Erwartete DPS | Ziel-TTK | HP (≈ DPS × TTK) | Besonderheit |
|---|---|---|---|---|---|---|
| Rusalka | 2 | Wiederkehrender Mini-Boss-Gegner | ~85 | ~25 s | ~2.100 | Song-Verzerrung, zieht Spieler |
| Poludnitsa | 2 | Scripted Mini-Boss (Mitte) | ~85 | ~30 s | ~2.600 | Verlangsamungs-Aura |
| Kaukas | 3 | Mini-Boss | ~100 | ~35 s | ~3.500 | Teleport, Gold-Bonus bei Sieg |
| Marzanna | 4 | Mini-Boss | ~120 | ~45 s | ~5.400 | Eisflächen-Hazard |
| Leshy | 1 | Hauptboss | ~380 | ~50 s | ~19.000 | Terrain-Veränderung |
| Baba Yaga (Hütte) | 2 | Hauptboss | ~380 | ~60 s | ~23.000 | schrumpfende Zone |
| Ältester Domovoi | 3 | Hauptboss | ~400 | ~75 s | ~30.000 | Add-Beschwörung |
| Chernobog | 4 | Hauptboss | ~420 | ~90 s | ~38.000 | Tag/Nacht-Phasen |
| Perun (seltener Spawn) | 4 | Seltener Mini-Boss | ~420 | ~50 s | ~21.000 | nach Sieg Verbündeter (Blitz + Buff) |

**Perun – seltener Mini-Boss mit Verbündeten-Mechanik:** Perun ist **nicht** Teil der garantierten Boss-Struktur. Er spawnt in Region 4 mit ca. **20 % Wahrscheinlichkeit** zwischen Minute 7–10 an einem zufälligen Punkt. Auf Sieg wird er für den Rest des Runs zum Verbündeten: alle ~6 s ein Blitzschlag auf die dichteste Gegnergruppe (Kettenschaden an bis zu 6 Gegner, je ~400 Schaden) + ~15 % Spieler-Schadensbuff. Da der Buff stark ist, ist die niedrige Spawn-Wahrscheinlichkeit der Balance-Anker – kein garantierter Power-Spike pro Run.

*Rollen-Klarstellung:* **Rusalka** ist ein wiederkehrender Mini-Boss-Gegner (kann mehrfach erscheinen), **Poludnitsa** der einmalige scripted Mini-Boss bei ca. 50 % der Run-Zeit (siehe Regionen-Dokument).

**Elite-Zwischenwellen:** Elite-HP = Standard-HP × `Ziel-Elite-TTK / Ziel-Trash-TTK`. Bei Trash ~0,4 s und Elite ~4 s ergibt das grob **×10** (nicht ×5 – die alte Faustregel machte Elites zu schnell sterblich). Beispiel: Aitvaras-Elite Region 1, Minute 5: `15 × 1.0 × 1.74 × 10 ≈ 261 HP` → bei ~60 DPS ca. 4,3 s TTK. Elites erscheinen ab Minute 5, danach ca. alle 60–90 s.

**Boss-HP-Skalierung:** Boss-HP ist **nicht** vom Zeit-Multiplikator betroffen (fixe Spawn-Zeitpunkte); der Regionen-Multiplikator ist bereits eingerechnet.

---

## 7. XP- & Level-Kurve

```
XP_bis_naechstes_Level(L) = round(6 × L ^ 1.5)
```

| Level | XP bis nächstes | Kumuliert (ab Level 1) |
|---|---|---|
| 1 → 2 | 6 | 6 |
| 5 → 6 | 67 | ~102 |
| 10 → 11 | 190 | ~666 |
| 15 → 16 | 349 | ~1.920 |
| 20 → 21 | 537 | ~4.030 |
| 25 → 26 | 750 | ~7.130 |
| 30 → 31 | 986 | ~11.340 |

**Ziel-Kadenz:** Level-Up etwa alle 20–25 s zu Beginn, später langsamer; **ca. 20–30 Level pro Run**. Da Gegner-XP weder über die Zeit noch stark über die Region skaliert, sorgen höhere Gegnerdichte (Punkt 3) und stärkere Waffen für die spätere XP-Zufuhr.

**XP-Menge pro Region:** Mit den XP-Werten aus Punkt 2 (1–4 pro Gegner) und den Kill-Zahlen aus Punkt 3.1.1 ergibt sich:

| Region | Ø XP/Kill | Ø Gesamt-XP/Run | Erreichtes Level (ca.) |
|---|---|---|---|
| 1. Dammerwald | ~2.2 | ~4.200 | 20 |
| 2. Sumpfmoor | ~2.8 | ~6.900 | 24 |
| 3. Dorf der Vergessenen | ~2.7 | ~8.200 | 26 |
| 4. Reich von Nav' | ~3.0 | ~11.400 | 30 |

→ Damit liegt **jede Region im Zielbereich von 20–30 Leveln**. Der ursprüngliche Entwurf (XP stark mit der Region skalierend) hätte in Region 4 Level 38–45 ergeben – deshalb sind die XP-Werte pro Gegner jetzt bewusst nahezu flach.

**Waffen-/Passiv-Level:** Waffen Level 1–8, Passiv-Items Level 1–5 (siehe Waffen-Evolutions-Dokument). Bei durchschnittlich 25 Level-Ups pro Run und 3 Karten zur Auswahl sollten im Schnitt 1–2 Waffen + 1 Evolution pro Run erreichbar sein – bewusst kein "alles vollleveln" in einem Run.

---

## 8. Waffen- & DPS-Skalierung (Referenz)

Damit die Gegner-HP-Werte oben einordenbar sind, hier die angenommene Schadensseite:

```
Waffen_DPS(Level) = Start_DPS × 1.30 ^ (Level - 1)
```
→ Stufe 8 = `1.30^7 ≈ 6.3×` Start-DPS. Beispiel Start-DPS 10 → Stufe 8 ≈ 63 DPS pro Waffe.

| Quelle | Effekt |
|---|---|
| 5 Waffen-Slots | Summe der Einzel-DPS |
| Krit (z. B. Jäger) | +8 % Chance × doppelter Schaden → ≈ +8 % Ø-DPS |
| Evolution | struktureller Effekt (AoE, Durchdringung, Stun) statt reiner Zahl |
| Passiv-Items | +5–25 % je Stat, multiplikativ auf Gesamt-DPS |

**Konsequenz für Gegner-HP:** Die Boss-HP in Punkt 6 ist direkt aus dieser DPS-Kurve × Ziel-TTK hergeleitet. Wer nur eine Waffe levelt, kämpft länger – das ist gewollt (Build-Entscheidung), nicht ein Balancing-Fehler.

---

## 9. Performance-Zielwerte (Kopplung an Technisches Konzept)

| Kennzahl | Zielwert | Messpunkt |
|---|---|---|
| Aktive Gegner (hart) | 85 | Region 4, Minute 9+ |
| Performance-Testwert | 100 | Meilenstein 0, Mittelklasse-Android |
| Framerate | 60 FPS (Minimum akzeptabel 30) | echte Geräte, nicht Editor |
| Projektile gleichzeitig | ≤ 150 | Schätzung für Object-Pool-Größe |
| SFX-Gleichzeitigkeit | geduckt ab 40 Gegner-Sounds | siehe Sound-Konzept Punkt 5 |

→ Der `SpawnDirector` liest den Deckel aus Punkt 3.2 und friert die Spawn-Rate ab Minute 9 ein – **eine einzige Quelle für diese Regel** (kein Duplizieren in Gegner-Skripten).

---

## 10. Balancing-Abstimmung mit anderen Dokumenten

| Thema | Entscheidung hier | Status in anderen Dokumenten |
|---|---|---|
| Upyr-Region | Region 2 (nicht 1) | Meilensteinplan M2 korrigiert |
| Gegnerzahl | 85 hart / 100 Testwert | Store-Listing ("85+") und Technisches Konzept (bis 85) angeglichen |
| Kaukas-Rolle | Mini-Boss **und** Hausgeist-Typ (zählt für Hausgeist-Boni) | Regionen-Dokument ergänzt |
| Run-Standardlänge | **12 Min** als Referenz-Run | GDD & Regionen auf 12-Min-Referenz präzisiert |
| Waffen-/Passiv-Slots | max. 5 aktiv + 5 passiv (nicht 6/6) | GDD §3.1 korrigiert |
| Kill-Zahl / Gold | ~1.900–3.800 Kills/Run, Ø-Gold/Kill 0.06–0.30 | Wirtschafts-Dokument auf Variante (a) umgestellt (Run-Gold & Talentkosten unverändert) |
| Rusalka-Rolle | wiederkehrender Mini-Boss-Gegner (Elite-Tier); Poludnitsa = scripted Mini-Boss | Setting-, Regionen- & Balancing-Dokument vereinheitlicht |
| Region-1-Mini-Boss | **keiner** – Region 1 bleibt Tutorial-Region mit nur einem Endboss | Regionen-Dokument dokumentiert |
| Regions-Freischaltung | **strikt linear** (Region n+1 nach Hauptboss-Sieg von Region n) | Regionen- & GDD-Dokument dokumentiert |
| Perun | **seltener** Mini-Boss (Region 4, ~20 %), nach Sieg starker Verbündeter | Setting-, Regionen-, Sound- & Balancing-Dokument aktualisiert |
| Doppel-Evolution | 2 kuratierte Kombis, Region 4 + Ahnen-Item, fusioniert zu 1 Slot | Waffen-Dokument dokumentiert (kein Gegner-Balancing nötig) |
| Reroll | 3 Gratis-Rerolls/Run, bis zu +2 via Talent „Wahrsagerei" | UI- & Wirtschafts-Dokument dokumentiert (kein Gegner-Balancing nötig) |

**Aufgelöster Widerspruch:** Das Wirtschafts-Dokument rechnete ursprünglich mit ~350–800 Kills/Run. Mit den Spawn-Kurven aus Punkt 3 sind es **~1.900–3.800** – das entspricht dem Genre-Standard. Umgesetzt wurde **Variante (a)**: Kill-Zahlen hoch, Ø-Gold-pro-Kill ~5× runter, sodass die Run-Gesamtsummen und damit die Talentbaum-Kosten praktisch unverändert bleiben.

---

## 11. Offene Punkte
- Feinjustierung der stückweisen HP-Kurve (Spike-Höhen) und der 0.30er-Spawn-Steigung nach ersten Performance-/Playtest-Daten
- Ob Schaden-Skalierung (linear) auf höheren Regionen doch stärker steigen muss, damit Region 4 ohne One-Shots fordernd bleibt – Playtesting
- Genaue `spawn_weight`-Werte pro Region als konkrete `.tres`-Zahlen (hier nur Prozent-Mix als Zielbild)
- Verhältnis Elite-Häufigkeit zu Spieler-DPS-Kurve (ob ×10 HP für Elites ab Minute 5 passt)

→ Alle tuning-relevanten Punkte mit Startwert, Messgröße und Anpassungsregel: `Playtesting_Tuning_Plan_v0.1.md` (Abschnitt 5.1).
