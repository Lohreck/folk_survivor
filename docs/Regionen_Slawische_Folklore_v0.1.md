# Regionen-Ausarbeitung: Slawisch/Baltische Folklore
### Ergänzung zum GDD "Survivor-Like Mobile" v0.1

---

## 1. Struktur-Prinzip

Jede Region ist eine eigene Map (freischaltbar über Meta-Progression), mit eigenem Gegner-Schwerpunkt, eigenem Umgebungs-Hazard und eigenem Boss am Ende der Zeitleiste. Innerhalb einer Region steigt die Gegnerdichte klassisch über die Run-Dauer (Standard-Run: 12 Min.), aber der Gegner-*Mix* verschiebt sich zusätzlich je nach Tageszeit-Phase (siehe Poludnitsa-Mechanik).

**Freischaltung:** Regionen werden **strikt linear** freigeschaltet – Region n+1 erst nach Sieg über den Hauptboss von Region n. Die Reihenfolge entspricht dem Schwierigkeitsgrad; erzählerisch "wandert" die Spielfigur einfach tiefer in die Geisterwelt hinein.

---

## 2. Region 1 – Der Dammerwald (Einstiegsregion)

**Thema:** Rand des verfluchten Waldes, noch nah an der "normalen" Welt – Nebel, knorrige Bäume, erste Anzeichen des Übernatürlichen

**Vorherrschende Gegner:** Kikimora (Schwarm), Domovoi (verdorben), vereinzelt Aitvaras
**Umgebungs-Hazard:** Dichter Nebel an Map-Rändern reduziert Sichtweite – rein visuell, kein Gameplay-Nachteil (schont Einsteiger)
**Boss:** **Leshy** – verändert Baumformationen, verlangt räumliches Ausweichen statt reiner Angriffs-Timing
**Mini-Boss:** **bewusst keiner** – Region 1 ist die Tutorial-Region. Der erste Mini-Boss ist Poludnitsa in Region 2; Leshy als Endboss reicht als Abschluss der Einstiegsregion aus.
**Zweck im Spielfluss:** Tutorial-artige Region, führt Kernmechaniken (Auto-Attack, Ausweichen, Level-Up-Auswahl) ohne Überforderung ein

---

## 3. Region 2 – Das Sumpfmoor

**Thema:** Wasser- und Moorlandschaft, tiefer im Wald, Übergang zur Geisterwelt spürbar (verzerrte Farben, gedämpftes Licht)

**Vorherrschende Gegner:** Vodyanoy (an Teiche gebunden), Rusalka (wiederkehrender Mini-Boss-Gegner, Elite-Tier), Upyr
**Umgebungs-Hazard:** Schlamm-Flächen auf der Map verlangsamen die Spielfigur beim Durchqueren – zwingt zu bewusster Routenwahl
**Mini-Region-Endboss (Zwischenpunkt, ca. Hälfte der Run-Zeit):** **Poludnitsa** – erscheint zur "Mittagszeit"-Phase, verlangsamt den Spieler in ihrer Nähe zusätzlich zum Schlamm-Hazard; ihre Niederlage schaltet für den Rest des Runs einen kleinen Buff frei (z. B. reduzierte Schlamm-Verlangsamung), was den zweiten Run-Abschnitt spürbar macht. *Abgrenzung:* Dies ist der **einmalige scripted Mini-Boss**; **Rusalka** ist dagegen ein wiederkehrender Elite-/Mini-Boss-Gegner ab ~Minute 5.
**Hauptboss:** **Baba Yagas Hütte** – bewegt sich über die Arena, verkleinert dynamisch den sicheren Bereich (Battle-Royale-artige Zonen-Mechanik im Kleinen)
**Zweck im Spielfluss:** Erste echte Schwierigkeitssteigerung durch Terrain-Interaktion (Verlangsamung + bewegliche Gefahr), zusätzlich durch den Mini-Boss ein spürbarer Zwischenschritt vor dem Hauptboss

---

## 4. Region 3 – Das Dorf der Vergessenen

**Thema:** Verlassenes Dorf, das von der Geisterwelt "verschluckt" wurde – Hausgeister sind hier zahlreich und feindselig geworden, da niemand mehr für sie sorgt

**Vorherrschende Gegner:** Domovoi (in großer Zahl, aggressiver als in Region 1), Velnias-Diener (Schild-Elite), Kikimora-Schwärme in noch höherer Dichte
**Umgebungs-Hazard:** Einstürzende Hausstrukturen als temporäre Deckung UND Gefahr (Trümmer können Schaden verursachen, wenn man zu lange in der Nähe bleibt)
**Mini-Region-Endboss (ca. Hälfte der Run-Zeit):** **Kaukas** – baltischer Hausgeist (zählt als Hausgeist-Typ, relevant für Hausgeist-Boni), der (anders als der Domovoi) Schätze hortet statt Haushalte zu beschützen; taucht an wechselnden verborgenen Stellen der Map auf, bewirft den Spieler mit gehortetem Hausrat/Gold und teleportiert sich kurz nach Treffern weg – zwingt zu ständigem Positionswechsel statt reinem Stehen-und-Ausweichen; Sieg gibt einen einmaligen Gold-Bonus für den Run
**Boss:** **Ältester Domovoi** – der letzte verbliebene Wächter des Dorfes, kämpft mit einer Mischung aus Nah- und Fernkampf (wirft Hausrat als Projektile, ruft zusätzlich kurzzeitig verdorbene Domovoi-Diener herbei) – thematisch die "dunkle Version" der schützenden Hausgeist-Figur aus der slawischen Folklore
**Zweck im Spielfluss:** Einführung der Schild-Mechanik (Velnias-Diener) als neue taktische Herausforderung vor der Endregion; Kaukas als beweglicher Zwischenschritt trainiert Positionswechsel, der Hauptboss kombiniert dann erstmals Fernkampf-Ausweichen mit Add-Management (die herbeigerufenen Diener)

---

## 5. Region 4 – Das Reich von Nav' (Endregion)

**Thema:** Die eigentliche Geisterwelt/Totenreich – surreale, sich verändernde Landschaft, dunkler Himmel, keine "normale" Umgebung mehr

**Vorherrschende Gegner:** Žaltys (Elite-Wellen), gemischte Elite-Spawns aus allen vorherigen Regionen (Schwierigkeits-Mix statt neuer Standard-Gegner)
**Umgebungs-Hazard:** Periodische "Nacht"-Phasen (visuell abgedunkelt), in denen alle Gegner kurzzeitig verstärkt werden – klare Vorwarnung nötig (z. B. Bildschirmvignette), damit es fair bleibt
**Mini-Region-Endboss (ca. Hälfte der Run-Zeit):** **Marzanna** – slawische Göttin des Winters und des Todes, friert Teile der Arena zu Eisflächen ein (rutschiger Untergrund, verändert Bewegungsverhalten), passt thematisch als Vorbote zu Chernobogs Tag/Nacht-Mechanik; Sieg schwächt kurzzeitig die Nacht-Verstärkung im restlichen Run ab
**Boss:** **Chernobog** – mehrphasig, Tag/Nacht-Mechanik als Kern des Kampfes
**Seltener Twist (nicht garantiert):** **Perun** erscheint mit ca. **20 % Wahrscheinlichkeit** als zusätzlicher, nicht-scripted Mini-Boss an einem zufälligen Punkt zwischen Minute 7–10. Wird er besiegt, wird er für den Rest des Runs zum **starken Verbündeten** (alle ~6 s ein Blitzschlag mit Kettenschaden auf die dichteste Gegnergruppe + ~15 % Spieler-Schadensbuff). Wird er nicht besiegt, bleibt er eine normale Bedrohung – kein Verbündeter. Bricht die reine Horde-Struktur auf und bietet einen erzählerischen Höhepunkt.
**Zweck im Spielfluss:** Höchste Schwierigkeit, Zusammenführung aller bisher gelernten Mechaniken (Terrain-Ausweichen, Zonen-Verkleinerung, Schild-Gegner, Elite-Dichte); Marzanna führt zusätzlich Boden-Hazards als letzte neue Mechanik vor dem Endkampf ein

---

## 6. Regionen-Übersicht (kompakt)

| Region | Thema | Kern-Mechanik | Mini-Boss | Hauptboss |
|---|---|---|---|---|
| 1. Dammerwald | Waldrand, Einstieg | Tutorial, Sichtweite | – | Leshy |
| 2. Sumpfmoor | Wasser/Moor | Verlangsamung, wasser­gebundene Gegner | Poludnitsa | Baba Yaga (Hütte) |
| 3. Dorf der Vergessenen | Verlassenes Dorf | Deckung/Trümmer-Hazard, Schild-Gegner | Kaukas | Ältester Domovoi |
| 4. Reich von Nav' | Geisterwelt/Totenreich | Tag/Nacht-Verstärkung, Elite-Mix | Marzanna | Chernobog (+ seltener Perun-Spawn) |

---

## 7. Offene Punkte
- Genaue Spawn-Kurven pro Region (wie schnell steigt Dichte, wann kommen erste Elites)
- **Entschieden:** Regionen werden **strikt linear** freigeschaltet (Region n+1 nach Hauptboss-Sieg von Region n) – kein paralleles Anwählen
- **Entschieden:** Region 1 bekommt **keinen** Mini-Boss – sie bleibt bewusst reine Tutorial-Region mit nur einem Endboss (Leshy)

→ Genaue Spawn-Kurven/Tuning: siehe `Balancing_Gegner_Spawnkurven_v0.1.md` und `Playtesting_Tuning_Plan_v0.1.md` (Abschnitt 5.1).
