# Sound- & Musik-Konzept (Detailausarbeitung)
### Ergänzung zum GDD "Survivor-Like Mobile" v0.1

---

## 1. Grundprinzip: Adaptive Musik nach Intensität

Statt einer linearen Musikspur pro Region nutzt das Spiel **vertikales Layering** (auch "Vertical Remixing" genannt): mehrere Instrumenten-Layer derselben Komposition laufen die ganze Zeit synchron im Hintergrund, werden aber je nach aktueller Gegnerdichte ein- bzw. ausgeblendet. Das ist Genre-Standard bei Horde-Survival-Spielen und lässt sich in Godot ohne komplexe Middleware umsetzen.

**Intensitätsstufen (gekoppelt an die Spawn-Kurve aus dem Balancing-Dokument):**

| Stufe | Trigger | Aktive Layer |
|---|---|---|
| 1 – Ruhig | Run-Start, 0–2 Min. | Nur Basis-Layer (Drone/Grundmelodie) |
| 2 – Aufbau | 3–5 Min. | + Rhythmus-Layer (Percussion einsetzend) |
| 3 – Dicht | 6–8 Min. | + Melodie-Layer (Hauptthema tritt hervor) |
| 4 – Chaos | 9–10 Min. (Spawn-Deckel erreicht) | + Zusätzlicher Intensitäts-Layer (höhere Tonlage, dichtere Percussion) |
| Boss-Kampf | Boss-Trigger | Wechsel auf eigene Boss-Komposition (siehe Punkt 4) |

**Technische Umsetzung (Godot):** Alle Layer als separate `AudioStreamPlayer`-Nodes, die von Anfang an synchron abgespielt werden (gleicher Loop-Punkt), Lautstärke wird über den `SpawnDirector` (siehe Technisches Konzept) je nach aktueller Gegnerzahl per `volume_db`-Interpolation weich ein-/ausgeblendet – kein hartes Umschalten, sondern Crossfades über 2–3 Sekunden, damit es nicht abrupt wirkt.

---

## 2. Instrumentierung pro Region

Jede Region hat eine eigene Instrumenten-Palette, die zum jeweiligen Thema passt und sich klanglich klar von generischer Fantasy-Orchestermusik abhebt (siehe Store-Listing-Dokument, Differenzierung als Verkaufsargument).

### Region 1 – Dammerwald
- **Basis-Layer:** Gezupfte Saiten (Gusli-artig, russisches Zupfinstrument), sparsam
- **Rhythmus-Layer:** Leiser Holz-Perkussion (Rahmentrommel-artig)
- **Melodie-Layer:** Einfache Flöten-Melodie, folkloristisch, in Moll
- **Ton:** Zurückhaltend, leicht mysteriös – passt zur Tutorial-Funktion der Region

### Region 2 – Sumpfmoor
- **Basis-Layer:** Tiefe, gedämpfte Streicher-Drones (falls Budget für Sample-Bibliothek vorhanden, sonst Synth-Pad mit organischem Filter)
- **Rhythmus-Layer:** Tropfende/Wasser-perkussive Elemente (Water-Drum-Sample oder prozedural erzeugtes Blubbern)
- **Melodie-Layer:** Gesangsähnlicher Klang ohne Text (Anspielung auf Rusalkas Gesang), leicht verhallt
- **Ton:** Schwerer, unheimlicher als Region 1

### Region 3 – Dorf der Vergessenen
- **Basis-Layer:** Knarrendes Holz, Glocken-Fragmente (Domovoi-Assoziation), sehr sparsam eingesetzt
- **Rhythmus-Layer:** Unregelmäßiger, fast "kaputter" Rhythmus – vermittelt das Gefühl von etwas Zerbrochenem/Verlassenem
- **Melodie-Layer:** Verstimmtes Klavier oder Music-Box-Klang – klassisches Horror-Stilmittel, hier folkloristisch eingefärbt
- **Ton:** Unheimlicher, leicht "wrong" klingend im Vergleich zu den Naturregionen davor

### Region 4 – Reich von Nav'
- **Basis-Layer:** Tiefe Chor-Drones (wortlos), sehr basslastig
- **Rhythmus-Layer:** Große, hallende Trommeln – wuchtig statt hektisch
- **Melodie-Layer:** Dissonante Bläser-/Horn-Klänge, die an rituelle Instrumente erinnern
- **Zusätzlicher Nacht-Phasen-Layer:** Bei Chernobogs periodischer Nacht-Mechanik (siehe Regionen-Dokument) blendet ein zusätzlicher, verzerrter Layer ein – rein akustisches Warnsignal, das die visuelle Vignette unterstützt

---

## 3. Instrument-Wiederverwendung als Wiedererkennungs-System

Statt für jede Region komplett neue Instrumente zu erfinden, trägt **ein Leitmotiv-Instrument** die gesamte Spielerfahrung: eine gezupfte Saite (Gusli/Kantele-artig) taucht in abgewandelter Form in allen vier Regionen auf – hell und einfach in Region 1, verzerrt/verhallt in Region 4. Das schafft klangliche Konsistenz, ohne die regionale Differenzierung zu verlieren, und ist produktionstechnisch günstiger als für jede Region komplett neue Instrumentierung zu schreiben.

---

## 4. Boss-Kämpfe – eigene Kompositionen

Jeder Hauptboss bekommt eine **eigene, in sich geschlossene Musik** (kein Layering-System wie im Run selbst), da Boss-Kämpfe kürzer und fokussierter sind:

| Boss | Musikalischer Ansatz |
|---|---|
| Leshy | Ruhiger Beginn, die bereits etablierte Flöten-Melodie aus Region 1 kehrt wieder, wird aber bei Terrain-Veränderungen (siehe Regionen-Dokument) durch kurze, perkussive Akzente unterbrochen – synchronisiert mit dem visuellen Terrain-Wechsel |
| Poludnitsa (Mini) | Kurzes, repetitives Motiv – bewusst simpel gehalten, da Mini-Boss |
| Baba Yaga | Stampfender, unregelmäßiger Rhythmus (passend zur beweglichen Hütte), Tempo zieht an, wenn sich die sichere Zone verkleinert |
| Kaukas (Mini) | Leicht "schelmisches" Motiv, tickende Percussion – unterstreicht die Teleport-Mechanik |
| Ältester Domovoi | Mischung aus der Dorf-Music-Box-Melodie und tieferen, bedrohlicheren Tönen – wird lauter/verzerrter, wenn Add-Diener herbeigerufen werden |
| Marzanna (Mini) | Kühle, glockenartige Klänge – akustische Entsprechung zum Eis-Hazard |
| Chernobog | Zwei klar unterscheidbare musikalische Zustände für Tag-/Nacht-Phase (siehe Regionen-Dokument) – Tag-Phase eher episch-orchestral, Nacht-Phase dissonant und bassbetont, harter akustischer Cut beim Phasenwechsel als zusätzliches Warnsignal |
| Perun (seltener Spawn) | Eigener Mini-Boss-Kampf-Track; beim Bündnis-Moment ein "Wendepunkt"-Sting, danach eine hellere, unterstützende Variante des Boss-Themas für den Rest des Runs |

---

## 5. Soundeffekte (SFX) – Design-Prinzipien

- **Klare Priorisierung:** Bei bis zu 85 gleichzeitigen Gegnern dürfen nicht alle Treffer-Sounds einzeln abgespielt werden (Audio-Chaos + Performance-Risiko) – stattdessen SFX-Pooling mit Lautstärke-Ducking: viele gleichzeitige gleiche Sounds werden zu einem einzigen, leicht lauteren "Gruppensound" zusammengefasst
- **Wichtige Sounds bekommen Vorrang:** Level-Up, Truhen-Öffnen, Boss-Phasenwechsel, eigene Treffer/Tod – diese SFX laufen auf einem separaten, nie geduckten Audio-Bus
- **Gegner-Sound-Identität:** Jeder Gegnertyp bekommt einen kurzen, klar unterscheidbaren Signatur-Sound (z. B. Kikimora = hohes Kichern, Upyr = tiefes Zischen) – hilft Spielern akustisch, Gefahren auch außerhalb des Sichtfelds wahrzunehmen (wichtig bei so vielen gleichzeitigen Gegnern auf kleinem Mobile-Screen)
- **Warnsignale konsistent gestalten:** Poludnitsas Zeitphase, Chernobogs Nacht-Phase, Marzannas Eis-Hazard – alle nutzen dieselbe akustische "Warnsignal-Sprache" (z. B. ein aufsteigender Ton), damit Spieler lernen, Gefahr am Klang zu erkennen, unabhängig vom konkreten Auslöser

---

## 6. Technische Umsetzung in Godot (Audio-Bus-Struktur)

```
Master
├── Music
│   ├── Layer_Basis
│   ├── Layer_Rhythmus
│   ├── Layer_Melodie
│   └── Layer_Intensitaet
├── SFX_Priority   (Level-Up, Truhen, Boss-Phasen, eigener Tod – nie geduckt)
├── SFX_Enemies    (Gegner-Sounds, wird bei hoher Gegnerzahl automatisch geduckt)
└── SFX_UI         (Menü-Klicks, unabhängig vom Spielgeschehen)
```

**Ducking-Logik:** `SFX_Enemies`-Bus-Lautstärke wird vom `SpawnDirector` (siehe Technisches Konzept) dynamisch an die aktuelle Gegnerzahl gekoppelt – mehr Gegner gleichzeitig = automatisch leiser pro Einzelsound, damit die Gesamtlautstärke nicht explodiert.

---

## 7. Offene Punkte
- Ob eigene Kompositionen budgetär machbar sind oder auf lizenzfreie/Library-Musik mit thematischer Anpassung zurückgegriffen werden muss
- Genaue Loop-Punkte/Taktzahlen müssten mit einem Komponisten/Sound-Designer abgestimmt werden
- Ob adaptive Musik on-the-fly gemischt wird (wie hier beschrieben) oder aus Kostengründen durch vorab gerenderte "Intensitätsstufen"-Dateien ersetzt wird (einfacher umzusetzen, aber weniger nahtlos)
- Lokalisierung der Gesangs-/Chor-Elemente (Region 2 und 4) – falls Text verwendet wird, welche Sprache (z. B. Altslawisch als authentische, aber unverständliche Option)

→ Tuning-Punkte (SFX-Ducking, Warnsignale) siehe `Playtesting_Tuning_Plan_v0.1.md` (Abschnitt 5.4); Budget-/Produktionsfragen siehe dort Abschnitt 8.
