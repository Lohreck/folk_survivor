# Playtesting- & Tuning-Plan
### Ergänzung zum GDD "Survivor-Like Mobile" v0.1

Hinweis: **Grobgerüst.** Dieses Dokument führt alle Tuning-Punkte aus den übrigen Dokumenten zusammen, gibt jedem einen **testbaren Startwert**, eine **Messgröße**, ein **Erfolgskriterium** und eine **Anpassungsregel**. Absolute Werte sind bewusst Startwerte – final entscheidet das Playtesting.

---

## 1. Grundprinzip

- **Zuerst Risiko, dann Feel, dann Inhalt** – die Testreihenfolge folgt dem Meilensteinplan.
- **Eine Änderung pro Iteration**, damit Effekte zuordenbar sind (kein gleichzeitiges Drehen an 5 Stellschrauben).
- **Telemetrie vor Bauchgefühl, Bauchgefühl vor Zahlen:** subjektives Feedback („fühlt sich der Build gut an?") zählt in diesem Genre genauso wie harte Kennzahlen.
- **Zielkorridor statt Fixwert:** Jeder Parameter hat einen akzeptablen Bereich; erst außerhalb wird nachjustiert.

---

## 2. Teststufen (an Meilensteine gekoppelt)

| Stufe | Meilenstein | Fokus | Kernfrage |
|---|---|---|---|
| A | M0 | Performance | Hält die Ziel-Gegnerzahl die Framerate? |
| B | M1 | Kern-Loop (Grey-Box) | Ist Ausweichen/Positionieren auch ohne Content fun? |
| C | M2 | Region 1 (Vertical Slice) | Stimmt die Schwierigkeitskurve bis zum Boss? |
| D | M3 | Meta-Schleife | Entsteht „one more run"? |
| E | M4–6 | Gesamtinhalt / Launch | Regionen-Difficulty, Retention, Monetarisierung |

---

## 3. Kern-Kennzahlen & Erfolgskorridore

| Kennzahl | Zielkorridor | Erhebung |
|---|---|---|
| Framerate (Mittelklasse-Android) | p50 ≥ 60 FPS, p95 ≥ 30 FPS | On-Device-Logging |
| Tod-Minute (Verteilung) | Mehrheit der Tode Min. 8–12; frühe Tode selten | Run-Telemetrie |
| Winrate pro Region (erstmalig) | R1 ~60–70 %, fallend bis R4 ~15–25 % | Run-Telemetrie |
| TTK Trash / Elite / Boss | 0,3–0,6 s / 3–8 s / 45–90 s | Testmessung |
| Erreichtes Level pro Run | 20–30 | Run-Telemetrie |
| Build-Varianz | keine Waffe/Evolution > 40 % Pickrate | Level-Up-Logging |
| Zeit bis Talentbaum-Stufe 10 | ~5–6 Runs | Meta-Telemetrie |
| Reroll-Nutzung | Ø 1–2 von 3 verbraucht | UI-Logging |
| Session-Länge | 12–18 Min. (Run + Meta) | Analytics |
| D1 / D7 Retention (ab Soft Launch) | genre-üblich (Zielwert separat recherchieren) | Analytics |

---

## 4. Benötigte Telemetrie-Events (früh einplanen)

| Event | Nutzen |
|---|---|
| `run_start` / `run_end` (Region, Charakter, Dauer, Todesminute, Sieg/Niederlage) | Difficulty-Kurve |
| `level_up` (gewählte Karte, Reroll ja/nein) | Build-Varianz, Reroll-Tuning |
| `weapon_evolved` / `double_evolved` | Erreichbarkeit der Evolutionen |
| `boss_spawn` / `boss_defeated` (Zeit bis Kill) | TTK-Boss |
| `perun_spawn` / `perun_defeated` | Seltenheits-Tuning |
| `gold_earned` (Quelle: Kills/Truhen/Boss) | Ökonomie |
| `talent_purchased` | Meta-Pacing |
| `enemy_count_sample` (1×/s, aktive Gegner) | Performance + Spawn-Tuning |
| `death_cause` (Gegnertyp/Schaden) | One-Shot-Erkennung |

---

## 5. Tuning-Register

### 5.1 Gegner & Spawn (Quelle: `Balancing_Gegner_Spawnkurven_v0.1.md`)

| Parameter | Startwert | Erfolgskriterium | Messgröße | Anpassungsregel |
|---|---|---|---|---|
| HP-Basiswachstum | ×1.10 / Min. | Trash-TTK 0,3–0,6 s über alle Minuten | TTK | > 0,6 s → auf ×1.07 senken; < 0,3 s → ×1.13 erhöhen |
| Spike Min. 5 / 7 | ×1.10 | Elite-TTK 3–8 s, kein „Wand"-Gefühl | Elite-TTK | ±0,05 je Iteration |
| Spike Min. 10 | ×1.15 | Finale fordernd, nicht ausweglos | Todesanteil Min. 10–12 | > 60 % Tode dort → Spike senken |
| Schaden-Skalierung | +0.03 / Min. (linear) | keine One-Shots ab Min. 8 | Max. Treffer / max. HP | > 40 % HP pro Treffer → Deckel niedriger |
| Spawn-Steigung | +0.30 / Min. | 85er-Cap ab Min. 9 erreicht | aktive Gegnerzahl | Cap zu früh → Steigung senken |
| Aktive-Cap-Rampe | `15 + 8×t` | keine Overloads Min. 1–3 | Tode Min. 1–3 | > 10 % frühe Tode → Rampe flacher |
| Elite-HP | ×10 Standard | Elite-TTK 3–8 s | Elite-TTK | anpassen ±2 |
| Regionen-Multiplikator | R2 1.5 / R3 2.2 / R4 3.2 (HP) | Winrate-Korridor pro Region | Winrate | Region zu hart → HP-Mult. −10 % |
| `spawn_weight`-Mix | %-Mix (Balancing §3.3) | Mix wirkt thematisch, keine Monotonie | Kill-Verteilung pro Typ | ein Typ > 50 % → Gewicht senken |
| XP-Kurve | `6 × L^1.5` | Level 20–30 pro Run | erreichtes Level | > 30 → Kurve steiler |
| Waffen-DPS/Level | ×1.30 | Build-Kurve passt zu Gegner-HP | DPS zu Min. X | TTK driftet → Basis anpassen |

### 5.2 Charaktere & Waffen (Quelle: `Charaktere_Ausdifferenzierung_v0.1.md`, `Waffen_Evolutionen_v0.1.md`)

| Parameter | Startwert | Erfolgskriterium | Messgröße | Anpassungsregel |
|---|---|---|---|---|
| Charakter-Passivs | 10 / 5 / 1 %·8 s / 20 / 8 / 10 / 20 % | kein Charakter strikt besser | Pickrate + Winrate je Char | Pick+Win > Durchschnitt+15 % → Passiv senken |
| Todesschnitt-Lifesteal | +10 %, Blutung 3× | kein HP-Snowball | HP-Verlauf über Run | HP dauerhaft > 90 % → Lifesteal senken |
| Reroll-Anzahl | 3 / Run (+2 via Talent) | Build-Konsistenz ohne Determinismus | Reroll-Nutzung, Build-Varianz | > 2,5 verbraucht → 2; < 1 → 4 |
| Doppel-Evo Ahnen-Item-Drop | ~8 % pro Elite in R4 | in ~1 von 4 R4-Runs erreichbar | `double_evolved`-Rate | zu selten → Drop erhöhen |
| Doppel-Evo-Stärke | Seelenmahd / Gewitteraxt (Effekt) | stark, aber andere Builds bleiben gültig | Winrate mit/ohne Fusion | trivialisiert → Effekt senken |
| Perun-Spawnchance | 20 % (R4, Min. 7–10) | selten, aber erlebbar | `perun_spawn`-Rate | < 10 % erlebt → auf 25 % |
| Perun-Verbündeten-Buff | ~400 Schaden/6 s + 15 % | spürbar stark, kein Auto-Win | Winrate mit Perun | > 95 % Winrate → Buff senken |

### 5.3 Meta-Ökonomie (Quelle: `Wirtschaft_Gold_Kurven_v0.1.md`)

| Parameter | Startwert | Erfolgskriterium | Messgröße | Anpassungsregel |
|---|---|---|---|---|
| Talent-Kostenkurve | `Basis × 1.35^(n-1)` | Stufe 10 nach ~5–6 Runs | `talent_purchased` | zu langsam → Basis 1.30 |
| Run-Gold (R2) | ~595 | fühlt sich lohnend, nicht inflationär | `gold_earned` | > 800 → Gold/Kill senken |
| Truhen pro Run | 2–3 | gleichmäßiger Belohnungs-Rhythmus | Truhen/Run | zu selten → Spawn-Chance |
| Gold-Rate-Talent | Basis 80 Gold | kein Runaway über Wochen | Gold/Run über Zeit | Soft-Cap bei +50 % |
| Battle-Pass-Preis | 500–800 Bernstein | Free-Spieler nach ~3–4 Wochen | Kauf-/Fortschrittsdaten | Launch-Daten abwarten |

### 5.4 Audio, UI & Barrierefreiheit (Quelle: `Sound_Musik_Konzept_v0.1.md`, `UI_UX_Layout_v0.1.md`, `Barrierefreiheit_...`)

| Parameter | Startwert | Erfolgskriterium | Messgröße | Anpassungsregel |
|---|---|---|---|---|
| SFX-Ducking-Schwelle | ab 40 Gegner-Sounds | kein Audio-Chaos, Warnsignale hörbar | subjektiv + Peak-Lautstärke | Clipping → Schwelle senken |
| Screen-Shake / Vignette | mittlere Intensität | Feedback klar, nicht reizüberflutend | subjektiv, A11y-Tester | Reizüberflutung → Default senken |
| Tutorial-Hinweise | 4–5 im ersten Run | verständlich, nicht aufdringlich | Anteil übersprungener Hinweise | > 50 % übersprungen → reduzieren |
| Farbenblind-Farbwerte | Protan/Deutan/Tritan-Presets | Gegner unterscheidbar | Simulations-Tools + Test mit Betroffenen | Unterscheidbarkeit < 100 % → Werte anpassen |
| Vereinfachtes HUD | optional | kognitive Entlastung | A11y-Feedback | nur aufnehmen, wenn nachgefragt |

---

## 6. Playtest-Ablauf

- **Intern (Stufe A–C):** tägliche Kurz-Sessions, Fokus auf konkrete Parameter, Think-Aloud-Protokoll
- **Extern klein (Stufe C–D):** 5–10 Personen, gemischte Erfahrung, Fragebogen + freie Beobachtung, **kein** Coachen
- **Geräte-Mix:** mind. 1 Low-End, 1 Mittelklasse, 1 High-End Android (Performance-Kernfrage aus M0)
- **Format:** landscape, 2–3 Runs pro Session, danach kurzes Interview (was war verwirrend? was hat Spaß gemacht?)
- **Auswertung:** pro Iteration genau **ein** Parameter ändern, Vorher/Nachher vergleichen

---

## 7. Priorisierung

1. **Performance (Stufe A):** blockiert alles andere – zuerst klären
2. **Gegner-/Spawn-Balancing (5.1):** bestimmt Difficulty-Kurve und TTK
3. **Charaktere/Waffen (5.2):** Build-Vielfalt, sobald Gegner stehen
4. **Ökonomie (5.3):** erst relevant, wenn Runs Spaß machen (M3)
5. **Audio/UI/A11y (5.4):** parallel, aber nicht launch-blockierend

---

## 8. Nicht per Playtesting lösbar (Produktions-/Extern-Entscheidungen)

Diese Punkte hängen an Budget, Recht oder Markt – hier nur als Restliste geführt:

- Sound: Eigenkomposition vs. Lizenzmusik; adaptive Mischung vs. gerenderte Stufen; Gesangs-Lokalisierung (`Sound_Musik_Konzept` §7)
- Store: Icon-Artwork, App-Titel-Trademark, Übersetzungsqualität (`Store_Listing` §8)
- Technik: AdMob-Plugin-Wahl, optionaler Web-Export, Git-Workflow für `.tscn` (`Technisches_Konzept` §11)
- Charaktere: dritter Region-4-Charakter, Skin-/Kosmetik-Varianten (`Charaktere` §4)
- Barrierefreiheit: konkrete Farbwerte nur mit echten Simulationstools/Betroffenen finalisierbar

---

## 9. Angewandte Iterationen (Tuning-Log)

Rückwirkendes Protokoll aller bereits umgesetzten Playtest-/Tuning-Schritte, ergänzend zu §1 ("eine Änderung pro Iteration"). Der Commit-Hash verlinkt auf die Detail-Begründung; neue Iterationen werden hier jeweils ergänzt.

| Datum | Iteration | Änderung | Grund (Feedback/Beobachtung) | Commit |
|---|---|---|---|---|
| 2026-09-21 | Lesbarkeit Platzhalter | neue, kontrastreichere Sprites; Projektile sichtbar gemacht | Playtest M2c: Figuren/Gegner schwer unterscheidbar | `4e7e82b` |
| 2026-09-21 | Kamera & Glow | Zoom 1.0 → 1.6, Glow-Vierecke entfernt | Screenshot-Diagnose: zu viel leere Fläche, Glow-Artefakte (u. a. unten rechts) | `dba8426` |
| 2026-09-23 | Region-Difficulty Dammerwald | hp_mult 1.0 → 0.8, damage_mult 1.0 → 0.8, spawn_basis 1.5 → 1.2/s | Ohne Meta-Progression (M3) kommt man nicht weit – Tutorial-Region soll moderat sein; Hebel gemäß Balancing §5 (Region-Multiplikatoren) | `5e3ccd0` |
| 2026-09-23 | Fernkämpfer-Verfolgbarkeit | Domovoi speed_mult 0.7 → 0.55, Aitvaras 1.0 → 0.8 (Projektil-Speed 320 px/s bewusst unverändert) | Fernkämpfer schwer zu treffen (Orbit-Logik + Schussdistanz) und trugen überproportional zur Schwierigkeit bei; Ausweichen bleibt Skill | `5c96976` |
| 2026-09-23 | Steuerung Zweistick | Zielstrecke rechts (Gamepad-Stick + Touch rechte Bildschirmhälfte), Auto-Aim bleibt Default | Produktänderung ggü. GDD "keine Zieltasten" nach Playtest-Wunsch; Umsetzung in GDD §5 und UI-UX-Layout §2 dokumentiert | `ee33802` |
| 2026-09-23 | Fernkämpfer-Schaden & Tempo | Domovoi Schaden 9 → 7, Tempo 0.55 → 0.45 (90 px/s); Aitvaras Schaden 7 → 6, Tempo 0.8 → 0.65 (130 px/s) | Playtest-Feedback: Treffer der Fernkämpfer noch zu schmerzhaft, Verfolger weiterhin zu schnell; Projektile (320 px/s) und HP bewusst unverändert | `d0be50e` |
| 2026-09-24 | Art-Upgrade Diablo-1-nah | Alle Sprites neu generiert (gedämpfte Palette, Licht von oben, Textur/Outline, Glut-Augen, Stickerei, Birkenflecken), Waldboden-Kachel 64×64 statt flacher ColorRect, Figuren aufrecht + flip_h statt Rotation, Feind-Materialien für Lesbarkeit unter CanvasModulate aufgehellt | Nutzerwunsch vor M2c-Abschluss: Platzhalter durch atmosphärische Grafik in Richtung Diablo 1 mit slawischem Stil ersetzen | `11c241e` |

**Offen, hängt am nächsten Playtest:**

- Zu leicht? → spawn_basis 1.2 → 1.35 (Balancing §5)
- Weiter zu schwer? → hp_mult 0.8 → 0.7
- Boss-TTK Leshy (19 000 HP, gerechnet mit ~380 DPS → ~50 s Kampf) im echten Run noch nicht verifiziert
- Tod-Minute-Korridor (§3: 8–12) und Winrate erst mit Telemetrie-Events (M3) messbar
