# Waffen-Evolutionskombinationen (Detailausarbeitung)
### Ergänzung zum GDD "Survivor-Like Mobile" v0.1

---

## 1. Grundprinzip

Jede der 5 aktiven Startwaffen erreicht bei **Level 8** ihre maximale Grundstufe. Ist zusätzlich das passende **Passiv-Item ebenfalls auf Maximalstufe** (Level 5, siehe Punkt 3), verschmelzen beide beim nächsten Level-Up-Fenster zu einer **Evolutionswaffe** – einem eigenständigen Waffentyp mit neuem Namen, neuem visuellen Effekt und einer strukturell veränderten Wirkweise (nicht nur höhere Zahlen).

**Warum dieses System:** Zwingt zu bewussten Build-Entscheidungen (welches Passiv nehme ich früh, um später eine bestimmte Evolution zu ermöglichen), ohne dass der Spieler raten muss – Level-Up-Screen kann ab Waffen-Level 6 einen kleinen visuellen Hinweis zeigen ("passendes Passiv fehlt noch"), um Klarheit zu schaffen.

---

## 2. Die fünf Evolutionen im Detail

### 2.1 Uralteichen-Axt
**Basis:** Axt des Holzfängers (Lv. 8) + **Leshy-Rinde** (Passiv, Lv. 5)
**Effekt:** Der Schwungradius verdoppelt sich, jeder Treffer verursacht zusätzlich einen kleinen Rückstoß-Effekt (Knockback), und getroffene Gegner erhalten für 2 Sekunden einen "Verwurzelt"-Debuff (-30% Bewegungsgeschwindigkeit)
**Thematik:** Die Axt verschmilzt optisch mit Wurzelwerk – passend zu Leshys Waldmagie
**Spielerischer Nutzen:** Starke Crowd-Control-Waffe gegen Schwärme (Kikimora), gut kombinierbar mit dem Holzfäller-Charakter (Tank-Archetyp)

### 2.2 Segenshufeisen
**Basis:** Eisernes Hufeisen (Lv. 8) + **Domovoi-Glöckchen** (Passiv, Lv. 5)
**Effekt:** Das Hufeisen durchdringt ab sofort alle getroffenen Gegner (kein Stopp mehr beim ersten Treffer) und kehrt danach weiterhin zum Spieler zurück; zusätzlich erhält jeder getroffene Hausgeist-Typ (Domovoi, Aitvaras, Kaukas) einen kleinen Extra-Schadensbonus
**Thematik:** Das Hufeisen wird von schützenden Symbolen umgeben – die klassische Volksglauben-Funktion als Geisterschutz wird spielmechanisch greifbar
**Spielerischer Nutzen:** Gute Wahl gegen Region-3-Gegnertypen (viele Hausgeister), Durchdringung macht es stark bei dicht gedrängten Gruppen

### 2.3 Loderndes Weihwasser
**Basis:** Weihwasser-Phiole (Lv. 8) + **Aitvaras-Feder** (Passiv, Lv. 5)
**Effekt:** Die Flächenwirkung hinterlässt eine brennende Zone, die 4 Sekunden lang anhält und kontinuierlich Schaden verursacht; gegen Geist-/Wasser-Gegner (Vodyanoy, Rusalka, Upyr) wird der Schaden verdoppelt
**Thematik:** Heiliges Wasser + Feuer des Hausdrachen ergibt eine Art "reinigendes Feuer"
**Spielerischer Nutzen:** Beste Wahl für Region 2 (viele wassergebundene Gegner), gut kombinierbar mit der Kräuterfrau (die ohnehin auf diese Waffe spezialisiert ist)

### 2.4 Todesschnitt
**Basis:** Sichel (Lv. 8) + **Rusalka-Träne** (Passiv, Lv. 5)
**Effekt:** Der Blutungs-Effekt stapelt sich jetzt bis zu 5-fach (statt nur 1x) und pro Blutungs-Tick wird ein kleiner Anteil des verursachten Schadens dem Spieler als HP zurückgegeben (Lifesteal)
**Thematik:** Die Sichel wird "durchsichtig" wie Wasser dargestellt – die Träne symbolisiert Trauer/Tod, passend zur Sensen-Assoziation
**Spielerischer Nutzen:** Starke Selbstheilungs-Option für fragile Charaktere (Kräuterfrau, Waisenkind), verwandelt reinen Damage-Dealer in Sustain-Waffe

### 2.5 Peruns Zorn
**Basis:** Donnerkeil (Lv. 8) + **Perun-Amulett** (Passiv, Lv. 5)
**Effekt:** Kettenschaden springt jetzt auf bis zu 6 Gegner (statt 3), und jeder 4. Treffer betäubt den getroffenen Gegner kurzzeitig (0.5s Stun)
**Thematik:** Volle Entfaltung des Donnergott-Symbols – visuell große Blitzkette über den Bildschirm
**Spielerischer Nutzen:** Beste Wahl für Region 4 (hohe Elite-Dichte), Stun-Chance hilft besonders gegen Schild-Gegner (Velnias-Diener), die sonst schwer zu unterbrechen sind

---

## 3. Passiv-Items – Übersicht (inkl. neuer Ergänzungen)

| Passiv-Item | Basis-Effekt (Lv. 1) | Effekt bei Lv. 5 (Max) | Gehört zu Evolution |
|---|---|---|---|
| Leshy-Rinde *(neu)* | +5% max. HP | +25% max. HP, +10% Rüstung | Uralteichen-Axt |
| Domovoi-Glöckchen | Aura verlangsamt schwache Gegner leicht | Aura-Radius verdoppelt, stärkere Verlangsamung | Segenshufeisen |
| Aitvaras-Feder | +5% Flächenschaden | +25% Flächenschaden, kleiner Feuer-Tick-Effekt | Loderndes Weihwasser |
| Rusalka-Träne *(neu)* | +2% Lifesteal bei Blutungseffekten | +10% Lifesteal, Blutung stapelt bis 3x | Todesschnitt |
| Perun-Amulett *(neu)* | +5% kritische Trefferchance | +15% kritische Trefferchance, +10% Fernkampfschaden | Peruns Zorn |

**Hinweis:** Alle Passiv-Items sind auch **ohne** die passende Waffe nutzbar (reine Stat-Boni) – die Evolution ist ein Bonus-Ziel, kein Zwang, um das Item sinnvoll einzusetzen.

---

## 4. Balancing-Prinzip für Evolutionen

- Evolutionswaffen sollen sich **strukturell**, nicht nur **numerisch** von der Basiswaffe unterscheiden (neue Mechanik: Durchdringung, Stapel-Effekte, Stun, Flächenbrand) – reine Zahlenerhöhung wäre für das Genre zu wenig belohnend
- Jede Evolution hat einen klaren **Situations-Vorteil** (siehe "Spielerischer Nutzen" oben), damit die Wahl der Evolution mit der aktuellen Region/Gegnersituation zusammenhängt, statt dass es eine objektiv "beste" Evolution gibt
- Alle 5 Evolutionen sind bewusst auf unterschiedliche Charakterarchetypen ausgerichtet (Tank, Hausgeist-Killer, AoE, Sustain, Elite-Killer) – sorgt für Build-Vielfalt über das gesamte Charakter-Roster hinweg
- Doppel-Evolutionen (Punkt 5) folgen denselben Prinzipien, werden aber über **Seltenheit** (Region 4 + Ahnen-Item) statt über Zahlen begrenzt

---

## 5. Doppel-Evolutionen (Endgame)

Zwei **fertige Evolutionswaffen** können zu einer ultimativen Waffe verschmelzen – das Endgame-Pendant zur normalen Evolution. Bewusst ein **seltenes Langzeitziel**, kein Bestandteil jedes Runs.

### 5.1 Ablauf
1. Beide Komponenten-Evolutionen sind erreicht (belegen je 1 Waffen-Slot)
2. Zusätzlich wird ein seltenes **Ahnen-Item** benötigt, das nur in **Region 4 (Reich von Nav')** aus Elite-Gegnern/Truhen fällt
3. Beim nächsten Level-Up-Fenster verschmelzen beide Waffen zu **einer** Doppel-Evolution → **ein Waffen-Slot wird frei**

### 5.2 Die zwei kuratierten Kombinationen

| Kombo | Ergebnis | Effekt |
|---|---|---|
| Todesschnitt + Loderndes Weihwasser | **Seelenmahd** | hinterlässt brennende Blutflächen; der Lifesteal stapelt sich auf den Flächen-DoT (starke Sustain-Variante) |
| Uralteichen-Axt + Peruns Zorn | **Gewitteraxt** | Verwurzelung + Kettenschaden; verwurzelte Gegner leiten die Blitzkette auf einen zusätzlichen Gegner weiter (Crowd-Control + Burst) |

**Warum nur zwei Kombinationen:** Fünf Evolutionen ergeben zehn Paarungen – jede bräuchte eigenes Artwork, VFX und Balancing. Zwei handverlesene Kombis sind produzierbar und klar lesbar; weitere können später folgen.

### 5.3 Design-Regeln
- **Seltenheit als Balance-Anker:** Nur in Region 4 und nur bei passendem Ahnen-Item-Drop – die Doppel-Evolution ist ein spätrun-Power-Spike (~Minute 10–12), kein garantierter Run-Bestandteil
- **Keine Abwertung anderer Builds:** Die Fusion darf nicht so stark sein, dass jede andere Kombination sinnlos wirkt – sie belohnt Commitment (zwei Waffen durchleveln), nicht Glück
- **UI:** Die Fusion erscheint als eigene Level-Up-Karte mit goldenem Rahmen (analog zum Evolutions-Hinweis), klar abgegrenzt von normalen Upgrades

---

## 6. Offene Punkte
- Ob ein Level-Up-Screen-Hinweis (siehe Punkt 1) technisch/visuell sauber umsetzbar ist, ohne den Screen zu überladen
- Feinbalancing der Prozentwerte (Playtesting nötig, besonders bei Todesschnitt-Lifesteal, das sich potenziell zu stark "snowballen" könnte)
- Feinbalancing der Doppel-Evolutionen (Drop-Wahrscheinlichkeit des Ahnen-Items, Stärke der Fusionseffekte) – siehe Punkt 5

→ Alle tuning-relevanten Punkte mit Startwert, Messgröße und Anpassungsregel: `Playtesting_Tuning_Plan_v0.1.md` (Abschnitt 5.2).
