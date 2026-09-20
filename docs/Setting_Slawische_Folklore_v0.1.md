# Setting-Ausarbeitung: Slawisch/Baltische Folklore
### Ergänzung zum GDD "Survivor-Like Mobile" v0.1

---

## 1. Grundidee & Ton

Statt klassischer Elfen/Orks/Drachen greift das Spiel auf slawische und baltische Mythologie zurück – ein im Mobile-Bereich fast unbenutztes Reservoir an Figuren. Setting: ein verfluchter Uralt-Wald irgendwo zwischen Realität und Geisterwelt (ähnlich dem russischen Begriff "Nav'" – dem Totenreich), in den die Spielfigur (freiwillig oder verschleppt) gerät.

**Ton:** düster-märchenhaft statt episch-heroisch. Eher "altes Volksmärchen, das man nachts am Lagerfeuer erzählt bekommt" als "Weltenretter-Fantasy".

---

## 2. Gegner-Roster

| Gegner | Herkunft | Verhalten | Schwäche/Besonderheit |
|---|---|---|---|
| **Kikimora** | Slawisch (Hausgeist, hier verwildert) | Schwarm-Gegner, klein, schnell, greift in Gruppen an | Standard-Schwarmfeind, geringe HP, hohe Anzahl |
| **Domovoi (verdorben)** | Slawisch (Hausgeist) | Mittlere Gegner, wirft Gegenstände (Fernkampf) | Wird bei Nähe schwächer, meidet Licht |
| **Upyr** | Slawisch (Vampir-Vorläufer) | Schnelle Verfolger, saugt bei Treffer HP vom Spieler ab | Anfällig gegen Feuer/Licht-Waffen |
| **Poludnitsa** | Slawisch ("Mittagsdämonin") | Erscheint in Wellen zur "Mittagszeit"-Phase des Runs, verlangsamt Spieler in ihrer Nähe | Zeitgebundener Elite-Spawn, gute Gelegenheit für Spezialwellen-Mechanik |
| **Vodyanoy** | Slawisch (Wassergeist) | Spawnt aus Teichen/Sümpfen auf der Map, zieht Spieler mit Sog-Angriff heran | An Wasserflächen der Map gebunden – gutes Level-Design-Element |
| **Rusalka** | Slawisch (Wassernymphe) | Wiederkehrender Mini-Boss-Gegner (Elite-Tier), singt (visueller Screen-Effekt: Bildschirmrand verzerrt sich), zieht Spieler an | Kann in Region 2 ab ~Minute 5 mehrfach auftauchen; thematisch mit Vodyanoy verwandt |
| **Aitvaras** | Baltisch (Hausgeist-Drache) | Fliegender Gegner, spuckt kleine Feuerprojektile | Einziger fliegender Standard-Gegner, sorgt für vertikale Abwechslung |
| **Žaltys (verflucht)** | Baltisch (heilige Schlange, hier korrumpiert) | Bodengebundener Elite, lange Angriffsreichweite (peitscht) | Gut als "Wellen-Elite" zwischen Bossen |
| **Velnias-Diener** | Baltisch (Unterweltgott, hier seine Schergen) | Mittelschwere Nahkämpfer mit Schild | Erste Gegner mit Blockmechanik – zwingt zu Flankierung |

---

## 3. Boss-Roster (pro Region ein Boss)

1. **Leshy** – Waldgeist/Waldhüter, erste Region. Verändert Baumformationen auf der Map während des Kampfes (Terrain-Hazard-Mechanik statt reiner Angriffsmuster)
2. **Baba Yaga** – zweite Region, ihre Hütte auf Hühnerbeinen bewegt sich über die Arena und verändert so ständig den sicheren Bereich
3. **Chernobog** – dunkler Gott, späte Region, klassischer Muster-Boss mit mehreren Phasen (Tag/Nacht-Mechanik: Angriffsmuster ändern sich, wenn er "Nacht" herbeiruft)
4. **Perun** – Donnergott, **seltener Mini-Boss-Spawn** (nicht in jedem Run garantiert). Erscheint in Region 4, bekämpft den Spieler erst und wird nach seiner Niederlage für den Rest des Runs zum **starken Verbündeten** (periodische Blitzschläge + Schadensbuff). Bricht die reine Horde-Struktur auf.

---

## 4. Waffen (thematisch angepasst)

| Waffe | Vorbild/Thema | Wirkweise |
|---|---|---|
| Axt des Holzfällers | Slawische Waldarbeiter-Tradition | Nahkampf, breiter Schwung, Standard-Startwaffe |
| Eisernes Hufeisen | Volksglaube: Schutz vor bösen Geistern | Wurfwaffe, bumerangartig zurückkehrend |
| Weihwasser-Phiole | Orthodoxe Segnungstradition | Flächenschaden gegen Wasser-/Geistgegner (Vodyanoy, Rusalka, Upyr) |
| Sichel | Erntesymbolik, auch mit Tod assoziiert | Schneller Nahkampf mit Blutungs-Effekt über Zeit |
| Donnerkeil (Perun-Symbol) | Baltisch/slawischer Donnergott | Blitzschlag-Fernkampf, Kettenschaden auf mehrere Gegner |
| Aitvaras-Feder | Vom Hausgeist-Drachen | Passiv/Evolutions-Item: verwandelt eine Waffe in einen Feuer-Flächeneffekt |
| Domovoi-Glöckchen | Hausgeist-Schutzsymbol | Passiv: Aura, die schwache Gegner (Kikimora) in Sichtweite verlangsamt |

**Evolutions-Beispiel:** Axt (Stufe 8) + Weihwasser-Phiole (Passiv) → **"Gesegnete Axt"**: Flächenschaden mit zusätzlichem Effekt gegen Geist-Gegnertypen

---

## 5. Charaktere (Startauswahl)

1. **Der Holzfäller** – Tank-Archetyp, Start mit Axt, hohe HP, langsame Bewegung
2. **Die Kräuterfrau** – Support/Glaskanone, Start mit Weihwasser-Phiole, schwache HP aber starker Flächenschaden gegen Geister
3. **Der Verbannte Soldat** – Ausgewogen, Start mit Sichel, durchschnittliche Werte, thematisch ein Mensch, der sich in den Wald verirrt hat
4. **Die Waisenkind-Figur** *(optional, freischaltbar)* – hohe Beweglichkeit, geringe HP, spezieller Bonus: Tiere/Hausgeister (Aitvaras, Domovoi-Typen) greifen sie seltener an – thematisch angelehnt an Märchenmotive vom "unschuldigen Kind, das Geister nicht verletzen"

*Hinweis:* Dies ist die frühe Startauswahl. Die vollständige, ausdifferenzierte Charakterliste mit **8 Charakteren** (inkl. Region-4-Charakteren und Freischaltbedingungen) steht in `Charaktere_Ausdifferenzierung_v0.1.md`.

---

## 6. Art Direction

- **Farbpalette:** gedämpfte Grün-/Brauntöne für den Wald, punktuelle warme Lichtquellen (Lagerfeuer, Hütten-Fenster) als Kontrastanker – passt gut zu eurem bereits etablierten Pixelart-Stil
- **Silhouetten:** Gegner klar über Umriss unterscheidbar (wichtig bei vielen gleichzeitigen Gegnern auf kleinem Mobile-Screen)
- **Wiederverwendung:** Tileset-Ansatz ähnlich eurem NetHack-Dungeon-Crawler-Projekt möglich (Sprite-Sheet-basiert), spart Produktionszeit

## 7. Sound Direction

- Traditionelle Instrumente als Basis (Gusli/Kantele-artige gezupfte Klänge) statt orchestraler Fantasy-Musik – klanglich unterscheidbar von der Konkurrenz
- Bei Baba-Yaga-Boss: Hühnerbeine-Hütte könnte ein eigenes, hölzernes Stampf-Sounddesign bekommen, das zusätzlich als Gefahren-Signal dient

---

## 8. Store-Differenzierung

- Icon/Key-Art mit Baba Yagas Hütte oder Leshy als Hauptfigur sticht optisch sofort aus dem Fantasy-Einheitsbrei heraus
- Beschreibung im Store-Listing kann gezielt "Slawische Mythologie" / "Baba Yaga" als Suchbegriffe nutzen – wenig Konkurrenz auf diesen Keywords im Vergleich zu "Dragon", "Elf", "Orc"

---

## 9. Offene Punkte
- **Regionen-Aufteilung** – ausgearbeitet: siehe `Regionen_Slawische_Folklore_v0.1.md`
- **Balancing der Werte (HP, Schaden, Spawn-Raten)** – ausgearbeitet: siehe `Balancing_Gegner_Spawnkurven_v0.1.md`
- **Perun als seltener Zwischenboss/Verbündeter** – entschieden: seltener Spawn in Region 4, nach Sieg starker Verbündeter (siehe Regionen-, Balancing- und Sound-Dokument)
