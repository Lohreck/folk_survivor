# Game Design Document – "Working Title"
### Bullet-Heaven / Survivor-Like für Mobile (Play Store)
**Version 0.1 – Erstentwurf**

---

## 1. Übersicht

| Feld | Wert |
|---|---|
| Genre | Bullet Heaven / Survivor-Like (Auto-Attack Horde-Shooter) |
| Plattform | Android (Play Store), Portierung auf iOS später denkbar |
| Engine | Godot 4.x (2D) |
| Zielgruppe | Casual-bis-Core-Mobile-Spieler, Fans von Vampire Survivors, Brotato, Survivor.io |
| Session-Länge | 12 Minuten pro Run (Standard-Run, 10–15 je nach Region) |
| Steuerung | Virtueller Joystick, Auto-Attack, keine Zieltasten |
| Monetarisierung | Free-to-Play: Rewarded Ads + Battle Pass + kosmetische/Charakter-IAPs |

---

## 2. Core Gameplay Loop

1. Spieler wählt Charakter + Startwaffe im Meta-Menü
2. Run startet auf einer Map, Gegnerwellen spawnen kontinuierlich und werden über Zeit dichter
3. Spieler bewegt sich (Joystick), Waffen feuern automatisch auf nächste Gegner
4. Getötete Gegner droppen XP-Gems → Level-Up → Auswahl aus 3 zufälligen Waffen-/Passiv-Upgrades (optionaler Reroll, siehe UI-Dokument)
5. Alle paar Minuten: Elite-Gegner oder Mini-Boss mit angekündigten Spezialangriffen
6. Run endet durch Spielertod oder Sieg über den Hauptboss (Sieg-Screen mit Loot-Zusammenfassung)
7. Belohnungen (Gold, Fragmente, XP) fließen in die Meta-Progression zurück

---

## 3. Progression

### 3.1 Run-interne Progression
- Waffen-Level 1–8, bei Stufe 8 mögliche **Evolution** durch Kombination mit passendem Passiv-Item (z. B. Waffe X + Passiv Y → Evolutions-Waffe)
- Passive Items: Bewegungsgeschwindigkeit, Angriffsradius, Cooldown-Reduktion, Magnet-Radius für Gems, HP-Regeneration
- Maximal 5 aktive Waffen- und 5 Passiv-Slots gleichzeitig

### 3.2 Meta-Progression (zwischen Runs)
- **Talentbaum**: dauerhafte Boni (Start-HP, Gold-Rate, Drop-Chance) gegen In-Run-Gold
- **Charaktere**: unterschiedliche Startwaffen, Passiv-Boni, Spielstile (Tank, Glaskanone, Support)
- **Karten/Biome**: schrittweise Freischaltung neuer Schauplätze mit eigenen Gegner-Sets und Hintergrundmusik (strikt linear: Region n+1 nach Hauptboss-Sieg von Region n)
- **Tägliche/Wöchentliche Herausforderungen**: Modifikatoren (z. B. "doppelte Gegnerdichte, dafür doppeltes Gold") für zusätzliche Belohnungen

---

## 4. Mobile-spezifisches Design

- **Auto-Aim/Auto-Attack ist Pflicht** – Touch-Eingabe ist zu ungenau für manuelles Zielen
- **Willkommens-Belohnung** beim App-Öffnen (kleine Gold-Menge) für bessere D1/D7-Retention
- **Session-Struktur**: Runs sind bewusst kürzer als am PC (ca. 12 statt 30 Min.), damit sie in Pendelzeiten passen
- **Rewarded Ads**:
  - "Zweite Chance" nach dem Tod (weiterspielen gegen Ad-Ansicht, 1x pro Run)
  - Doppelte Run-Belohnung gegen freiwilligen Ad
  - Täglicher Bonus-Truhe-Ad
- **Performance**: Object Pooling für Gegner/Projektile zwingend (kein Instantiate/Destroy pro Frame), Ziel: stabil auf Mittelklasse-Geräten

---

## 5. Monetarisierung

| Element | Beschreibung |
|---|---|
| Battle Pass | Saisonal (4–6 Wochen), kosmetische Skins + Charaktere, Free- und Premium-Track |
| Charakter-Freischaltung | Über Ingame-Währung ODER Echtgeld, kein Pay-to-Win bei Kernmechanik |
| Rewarded Ads | Freiwillig, gegen spürbare Belohnungen (siehe oben) |
| Kosmetik-IAPs | Skins, Waffen-Effekte, Charakter-Auren – rein visuell |

**Prinzip:** Kernmechanik bleibt fair (kein Pay-to-Win), sonst leiden Store-Bewertungen und organisches Wachstum.

---

## 6. Setting – Vorschläge (bewusst NICHT High-Fantasy)

Der Markt ist mit Fantasy-Settings übersättigt. Hier sechs Alternativen mit unterschiedlichem Ton, jeweils mit kurzer Begründung zur Store-Tauglichkeit:

### A. Tiefsee-Abgrund
Verlassene Bathyscaphe-Forschungsstation, die von bioluminiszenten Tiefsee-Kreaturen überrannt wird. Enge, klaustrophobische Beleuchtung (Taschenlampen-Kegel als visuelles Alleinstellungsmerkmal), Sound-Design mit Sonar-Pings. Hoher Wiedererkennungswert in Store-Screenshots durch das dunkle, kontrastreiche Farbschema.

### B. Mikrokosmos / Immunsystem
Spieler ist eine Nano-Einheit, die Viren und Bakterien in einem menschlichen Körper bekämpft. Organische, abstrakte Gegner-Designs (Zellen, Antikörper-Waffen), sehr farbenfrohe Bio-Ästhetik. Ungewöhnlich genug, um in Store-Thumbnails sofort aufzufallen.

### C. Verlassene Raumstation (Cosmic Horror light)
Alien-Parasiten befallen eine Forschungsstation im All. Sci-Fi-Horror-Ton, Metall/Neon-Optik, gut kombinierbar mit "Alien"-Fans als Zielgruppe. Waffen wirken technischer (Plasma, Laser) statt magisch.

### D. Dieselpunk-Industriestadt
1920er-Jahre-inspirierte Fabrikstadt, überrannt von mechanischen Automaten/Golems, die außer Kontrolle geraten sind. Rost-Braun/Messing-Farbpalette, Dampf- und Zahnrad-Ästhetik statt klassischer Fantasy-Elemente – fühlt sich "erwachsener" an.

### E. Arktis-Forschungsstation
Etwas mutiert in ewigem Eis (angelehnt an "The Thing"), Spieler kämpft gegen sich wandelnde Kälte-Kreaturen in einer isolierten Polarstation. Weiß/Blau-Kontrast mit warmen Lichtquellen als visueller Anker, starke Horror-Atmosphäre ohne explizit gruselig zu sein.

### F. Slawisch/baltische Folklore (statt generischer Fantasy)
Weniger ausgelutschtes Mythologie-Set (Leshy, Rusalka, Domovoi statt Elfen/Orks/Drachen). Düsterer Wald-Look, der sich gut mit eurem bestehenden Pixelart-Stil aus dem Dungeon-Crawler-Projekt kombinieren ließe, aber klar ein eigenes visuelles Profil behält.

**Empfehlung:** A (Tiefsee) oder C (Raumstation) bieten die stärkste Differenzierung im Store, weil Screenshots sofort erkennbar anders wirken als die üblichen grün-braunen Fantasy-Horden-Shooter. F eignet sich am besten, falls ihr eure bestehende Pixelart-Assets/Erfahrung aus dem Dungeon-Crawler-Projekt wiederverwenden wollt.

**Getroffene Entscheidung:** Das Projekt setzt **Option F (Slawisch/Baltische Folklore)** um. Alle weiteren Dokumente (Setting, Regionen, Charaktere, Waffen, Sound, Store) bauen darauf auf – siehe `Setting_Slawische_Folklore_v0.1.md`. Die Optionen A–E bleiben als Ideen für spätere Projekte dokumentiert.

---

## 7. Offene Punkte (für spätere Ausarbeitung)
- **Setting** – entschieden: Slawisch/Baltische Folklore (Option F), siehe `Setting_Slawische_Folklore_v0.1.md`
- **Waffenliste + Evolutionen** – siehe `Waffen_Evolutionen_v0.1.md`
- **Gegner-Roster** – siehe `Setting_Slawische_Folklore_v0.1.md` + `Regionen_Slawische_Folklore_v0.1.md`
- **Charakterliste** – siehe `Charaktere_Ausdifferenzierung_v0.1.md`
- **Wirtschafts-Balancing** – siehe `Wirtschaft_Gold_Kurven_v0.1.md`
- **Kampf-/Spawn-Balancing** – siehe `Balancing_Gegner_Spawnkurven_v0.1.md`
