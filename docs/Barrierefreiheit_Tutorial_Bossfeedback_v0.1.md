# Barrierefreiheit, Tutorial-Overlay & Boss-Phasenwechsel-Feedback
### Ergänzung zum GDD "Survivor-Like Mobile" v0.1

---

## Teil 1: Barrierefreiheit

### 1.1 Farbenblind-Modus

**Problem:** Bei bis zu 85 gleichzeitigen Gegnern ist schnelle visuelle Unterscheidung kritisch – reine Farbcodierung (z. B. "rote Gegner sind gefährlicher") schließt Spieler mit Farbfehlsichtigkeit faktisch aus einem Kern-Skill des Genres aus.

**Lösung – doppelte Kodierung von Anfang an, nicht nachträglich:**
- Jeder Gegnertyp unterscheidet sich zusätzlich zur Farbe über **Silhouette/Form** (bereits im Setting-Dokument als Grundprinzip festgelegt – "Gegner klar über Umriss unterscheidbar")
- Gefahren-Indikatoren (z. B. Poludnitsas Verlangsamungs-Aura, Marzannas Eisflächen) nutzen zusätzlich **Muster** (gestrichelte Linien, Schraffur) statt nur Farbfläche
- Optionaler Menüpunkt "Farbenblind-Modus" (Protanopie/Deuteranopie/Tritanopie-Presets) passt vor allem HUD-Elemente (HP-Leisten, Warnvignetten) an – Gegner-Silhouetten bleiben unverändert, da sie bereits formbasiert unterscheidbar sind

### 1.2 Schriftgrößen-Skalierung

- UI-Text (Level-Up-Karten, Menüs) unterstützt eine Skalierungsstufe (Standard/Groß), gesteuert über Systemeinstellung des Geräts (Android Accessibility-Schriftgröße) automatisch übernommen, plus manueller Override im Spiel-Einstellungsmenü
- **Wichtig:** Level-Up-Karten-Layout (siehe UI/UX-Dokument) muss bei größerer Schrift nicht umbrechen – Kurzbeschreibungen bewusst auf max. 1 Zeile begrenzt, das zahlt sich hier aus

### 1.3 Ein-Hand-Bedienbarkeit (bereits im Kern-Design verankert)

- Dynamischer Joystick (erscheint dort, wo der Daumen aufsetzt) statt fixer Position – kommt sowohl kleineren Händen als auch Spielern mit eingeschränkter Reichweite entgegen
- Kein Multi-Touch-Zwang (kein gleichzeitiges Ziehen + Tippen nötig, da Auto-Attack) – das Spiel ist dadurch von Grund auf eher barrierearm als die meisten Action-Genres

### 1.4 Weitere Optionen (Menüpunkt "Barrierefreiheit")

| Option | Zweck |
|---|---|
| Screen-Shake-Intensität (0–100%) | Für Spieler mit vestibulären Empfindlichkeiten oder Reizüberflutung |
| Blitz-/Flacker-Reduktion | Reduziert schnelle Helligkeitswechsel (relevant bei Chernobogs Tag/Nacht-Wechsel, siehe Teil 3) |
| Audio-Untertitel für wichtige akustische Warnsignale | Für hörgeschädigte Spieler – textuelle/visuelle Entsprechung der Sound-Warnsignale aus dem Sound-Konzept |

---

## Teil 2: Tutorial-Overlay

### 2.1 Grundprinzip: Lernen durch Tun, nicht durch Lesen

Kein klassischer Tutorial-Textblock vor Spielstart – stattdessen **kontextuelle Hinweise**, die genau dann erscheinen, wenn die jeweilige Mechanik zum ersten Mal relevant wird. Deckt sich mit der bereits festgelegten Funktion von Region 1 als "Tutorial-artige Region" (siehe Regionen-Dokument).

### 2.2 Ablauf der ersten Minuten (Region 1, erster Run überhaupt)

| Zeitpunkt | Hinweis | Darstellung |
|---|---|---|
| Sofort bei Run-Start | Kurzer, halbtransparenter Pfeil auf den Bildschirmbereich, wo der Joystick erscheinen wird | Verschwindet nach erster Berührung |
| Erster Gegner in Reichweite | Kein Hinweis nötig (Auto-Attack passiert automatisch – Spieler sieht es einfach) | – |
| Erster XP-Gem-Drop | Kurzer Text "Sammle Erfahrung ein" mit Pfeil auf den Gem | Verschwindet nach Einsammeln |
| Erstes Level-Up | Level-Up-Screen selbst braucht keinen Zusatz-Text – Layout ist selbsterklärend (3 klar beschriftete Karten) | – |
| Erste Begegnung mit einem neuen Gegnertyp (z. B. Domovoi mit Fernkampf) | Kein Overlay-Text, aber der Gegner-Signatur-Sound (siehe Sound-Konzept) macht ihn akustisch bemerkbar | – |
| Erste Verwundung | Kurzes rotes Bildschirmrand-Blinken (auch schon Grundfeedback fürs restliche Spiel, hier nur erstmals erklärt: "Achtung, du wurdest getroffen!") | Einmaliger Text, danach nie wieder |

### 2.3 Design-Prinzip

- **Maximal 4–5 Hinweise im gesamten ersten Run** – alles darüber hinaus wirkt aufdringlich und unterbricht den Spielfluss, den das Genre gerade über schnelles "Reinkommen" verkauft
- Alle Hinweise sind **überspringbar** (Tap irgendwo schließt sie sofort) – erzwingt nichts
- Hinweise erscheinen **nie während Kampfgetümmel mit hoher Gegnerdichte** – nur in den ruhigeren ersten 1–2 Minuten der Region 1, danach ist das Tutorial "vorbei", auch wenn der Spieler noch nicht alle Mechaniken gesehen hat (z. B. Bosskampf-Mechaniken werden nicht vorab erklärt, sondern sind selbst der erste Kontaktpunkt – siehe Teil 3)

### 2.4 Kein Tutorial für Meta-Progression

Talentbaum, Charakterauswahl etc. brauchen kein Overlay-Tutorial – diese Screens sind aus anderen Mobile-Spielen so vertraut (Karten-Raster, Kauf-Buttons), dass ein Hinweis hier eher bevormundend als hilfreich wirken würde.

---

## Teil 3: Visuelles Feedback bei Boss-Phasenwechseln

### 3.1 Grundprinzip: Klare Eskalationsstufen statt Überraschung

Boss-Phasenwechsel sind Fairness-kritisch (siehe bereits im Regionen-Dokument angedeutet: "klare Vorwarnung nötig, damit es fair bleibt"). Jeder Phasenwechsel folgt derselben dreiteiligen Struktur, damit Spieler das Muster genrell lernen und nicht pro Boss neu interpretieren müssen:

1. **Vorwarnung** (0.5–1 Sek. vorher): kurzes, spezifisches visuelles Signal
2. **Übergang** (Moment des Wechsels): kurzer, klar abgegrenzter Effekt
3. **Neuer Zustand** (danach durchgehend sichtbar): dauerhafter visueller Marker, solange die Phase aktiv ist

### 3.2 Konkrete Umsetzung je Boss-Mechanik

| Mechanik | Vorwarnung | Übergang | Neuer Zustand |
|---|---|---|---|
| Leshy – Terrain-Veränderung | Betroffene Bodenfläche beginnt 0.5s vorher leicht zu vibrieren/pulsieren | Kurzer Partikel-"Aufreiß"-Effekt am Boden | Neue Baumformation bleibt sichtbar bis zur nächsten Änderung |
| Baba Yaga – Zonen-Verkleinerung | Äußerer Rand der neuen (kleineren) Zone blinkt kurz auf | Übergangsring zieht sich sichtbar zusammen (keine harte Sprung-Änderung) | Bereich außerhalb der Zone erhält eine gedimmte Überlagerung (nicht komplett schwarz, aber klar abgesetzt) |
| Ältester Domovoi – Add-Beschwörung | Kurzer Lichtschein an den Spawn-Punkten der Diener | Diener "materialisieren" mit kurzem Aufblitz-Effekt | Diener selbst sind normal sichtbar, keine Dauermarkierung nötig |
| Marzanna – Eisflächen | Boden verfärbt sich 0.5s vorher leicht bläulich, bevor er zufriert | Kurzer Frost-Ausbreitungs-Effekt vom Zentrum nach außen | Zugefrorene Fläche bleibt durchgehend visuell anders texturiert (glänzend/reflektierend) als normaler Boden |
| Chernobog – Tag/Nacht-Wechsel | Bildschirmrand beginnt sich 1 Sek. vorher langsam zu verdunkeln (Vignette baut sich auf) | Kurzer, harter Screen-Flash-Moment beim eigentlichen Wechsel (mit Screen-Shake-Optionsanbindung, siehe Teil 1) | Durchgehend abgedunkelte Farbpalette + Partikel-Overlay, solange Nacht-Phase aktiv ist; kehrt bei Tag-Rückkehr in normale Palette zurück |

### 3.3 Zusammenspiel mit Barrierefreiheit

- Der harte Screen-Flash bei Chernobogs Wechsel wird durch die "Blitz-/Flacker-Reduktion"-Option (Teil 1.4) automatisch durch einen weicheren Crossfade ersetzt, ohne dass die Information (Phase hat gewechselt) verloren geht
- Alle Vorwarnungen sind **nicht ausschließlich farbbasiert** (Vibrieren, Aufblitzen, Formänderung), damit sie auch mit Farbenblind-Modus funktionieren – konsistent mit dem Grundprinzip aus Teil 1.1

### 3.4 Akustische Kopplung (Verweis auf Sound-Konzept)

Jede Vorwarnungs-Stufe hat eine passende akustische Entsprechung aus der im Sound-Konzept festgelegten "Warnsignal-Sprache" (aufsteigender Ton) – visuelles und akustisches Feedback laufen synchron, damit Spieler die Information über beide Kanäle gleichzeitig bekommen, nicht nur redundant, sondern auch für Spieler mit eingeschränktem Hör- oder Sehvermögen zugänglich.

---

## Offene Punkte
- Konkrete Farbwerte für den Farbenblind-Modus (müsste mit echten Simulationstools für Protanopie/Deuteranopie/Tritanopie getestet werden)
- Ob ein optionales "Vereinfachtes HUD" für Spieler mit kognitiven Einschränkungen sinnvoll wäre (reduziert auf die absolut notwendigen Elemente)
- Playtesting mit tatsächlich farbfehlsichtigen Spielern, um die Silhouetten-Unterscheidbarkeit zu verifizieren, bevor die finale Grafikproduktion beginnt

→ Alle tuning-relevanten Punkte mit Startwert, Messgröße und Anpassungsregel: `Playtesting_Tuning_Plan_v0.1.md` (Abschnitt 5.4).
