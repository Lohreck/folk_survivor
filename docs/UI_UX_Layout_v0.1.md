# UI/UX-Layout
### Ergänzung zum GDD "Survivor-Like Mobile" v0.1

---

## 1. Grundprinzipien

- **Zwei-Hand-Bedienbarkeit im Run (Twin-Stick):** Der linke Daumen bewegt (linke Bildschirmhälfte), der rechte Daumen zielt (rechte Bildschirmhälfte); alle weiteren interaktiven Elemente während des Gameplays liegen in der unteren Bildschirmhälfte (Daumen-Reichweite)
- **Landscape-Orientierung** (siehe Technisches Konzept) – HUD-Elemente entsprechend links/rechts statt oben/unten verteilt, um die vertikal begrenzte Höhe nicht zu überladen
- **Reduktion während des Kampfes:** Je mehr auf dem Bildschirm passiert (hohe Gegnerdichte), desto wichtiger ist ein aufgeräumtes HUD – keine überflüssigen Elemente, die von der eigentlichen Gefahr (Gegnerpositionen) ablenken

---

## 2. HUD-Anordnung während eines Runs

```
┌─────────────────────────────────────────────────────────┐
│ [Zeit 09:42]                          [Pause-Button]    │  oben
│                                                           │
│                                                           │
│                    (Spielfeld / Kampfzone)                │  mitte
│                                                           │
│                                                           │
│ [XP-Leiste, volle Breite unten]                          │
│ [Joystick]      [Charakter-Icon]    [Boss-HP, falls aktiv]│  unten
└─────────────────────────────────────────────────────────┘
```

**Element-Details:**

| Element | Position | Verhalten |
|---|---|---|
| Zeit-Anzeige | Oben mittig | Statisch sichtbar, ändert sich nicht bei Chaos |
| Pause-Button | Oben rechts | Klein, außerhalb der Daumen-Reichweite bewusst (verhindert versehentliches Pausieren im Kampfgetümmel) |
| XP-Leiste | Unten, volle Breite | Füllt sich kontinuierlich, dezente Pulsation kurz vor Level-Up als visuelle Vorwarnung |
| Virtueller Joystick | Unten links | Erscheint an der Stelle, wo der Daumen zuerst aufsetzt (dynamisches Joystick-Prinzip, kein fixer Kreis) – vermeidet unbequeme Handhaltung |
| Ziel-Stick (Twin-Stick) | Rechte Bildschirmhälfte | Zweiter, identisch dynamischer Joystick für die Blickrichtung – parallel zum Bewegungs-Stick mit dem rechten Daumen bedienbar. Gamepad: rechter Stick (`aim_*`-Aktionen), linker Stick/D-Pad bewegt |
| Charakter-HP | Kleine Anzeige direkt am Charakter-Icon/Sprite selbst (nicht separat im HUD) statt als klassischer Lebensbalken oben | Reduziert Blickwechsel – Spieler schaut ohnehin auf die eigene Spielfigur |
| Boss-HP-Leiste | Oben, erscheint nur während Boss-/Mini-Boss-Kämpfen | Ausgeblendet in Standard-Wellen, um HUD-Überladung zu vermeiden |

**Bewusst NICHT im HUD:** Waffen-Cooldown-Anzeigen (da alles automatisch feuert – hätte keinen Handlungswert für den Spieler), Minimap (bei kurzen 12-Minuten-Runs auf relativ kompakten Maps nicht notwendig)

---

## 3. Level-Up-Auswahl-Screen

**Grundverhalten:** Spiel pausiert vollständig bei Level-Up (kein Echtzeit-Weiterlaufen im Hintergrund – anders als bei manchen Genre-Vertretern, aber auf Mobile wichtig, da Touch-Eingaben bei gleichzeitig weiterlaufendem Gameplay zu Fehlentscheidungen unter Zeitdruck führen können)

**Layout:**

```
┌─────────────────────────────────────────────┐
│              Stufe erreicht!                 │
│                                               │
│   ┌──────────┐  ┌──────────┐  ┌──────────┐  │
│   │  Icon     │  │  Icon     │  │  Icon     │  │
│   │  Name     │  │  Name     │  │  Name     │  │
│   │  Kurzbe-  │  │  Kurzbe-  │  │  Kurzbe-  │  │
│   │  schreib. │  │  schreib. │  │  schreib. │  │
│   │  Lv. 3→4  │  │  Lv. NEU  │  │  Lv. 2→3  │  │
│   └──────────┘  └──────────┘  └──────────┘  │
│                                               │
│    [Reroll-Karte: nur sichtbar, solange Rerolls übrig]    │
└─────────────────────────────────────────────┘
```

**Details pro Karte:**
- Icon (Waffe/Passiv-Symbol), Name, eine kurze Beschreibung (max. 1 Zeile, z. B. "+15% Schaden"), aktuelle→neue Stufe
- **Evolution-Hinweis** (siehe Waffen-Evolutionen-Dokument): Falls eine Karte eine Waffe zeigt, die bei dieser Wahl evolvieren würde, erhält die Karte einen dezenten goldenen Rahmen + kleines Sonderzeichen – kein zusätzlicher Text nötig, rein visuelle Auszeichnung
- Karten sind **groß genug für Daumen-Tap** (keine kleinen Buttons) – gesamte Karte ist die Tap-Fläche, nicht nur ein kleiner Button darauf
- **Reroll:** Ein separater 4. Slot mit Reroll-Symbol erscheint nur, solange Rerolls übrig sind, und zeigt die Restanzahl. Auch hier ist die gesamte Karte Tap-Fläche. Ein Reroll zieht die 3 Angebotskarten neu; Evolutions-/Fusions-Hinweise (goldener Rahmen) werden dabei neu berechnet. Standard: **3 Gratis-Rerolls pro Run**, kein Zeitdruck (Spiel ist ohnehin pausiert). Über den Talentbaum-Knoten „Wahrsagerei" (siehe Wirtschafts-Dokument) sind bis zu **+2** zusätzliche Start-Rerolls freischaltbar.

**Warum 3 Karten als Standard (statt z. B. 4):** Auf kleinen Mobile-Screens im Querformat wird es bei 4 Karten schnell eng für lesbaren Text – 3 Karten sind ein guter Kompromiss zwischen Auswahlvielfalt und Lesbarkeit. Der Reroll belegt **keinen** regulären Karten-Slot, sondern ist ein separater, nur zeitweise sichtbarer 4. Slot.

---

## 4. Menüstruktur (Gesamtübersicht)

```
Hauptmenü
├── Spielen → Charakterauswahl → Regionsauswahl → Run startet
├── Meta-Fortschritt
│   ├── Talentbaum
│   ├── Charaktere (Übersicht + Freischaltung)
│   └── Regionen (Übersicht + Freischaltung)
├── Battle Pass
├── Shop (Kosmetik, Bernstein-Käufe)
├── Herausforderungen (Täglich/Wöchentlich)
└── Einstellungen
    ├── Audio (Musik/SFX getrennt regelbar)
    ├── Grafik (falls Performance-Modus nötig)
    └── Barrierefreiheit (siehe Offene Punkte)
```

**Navigationsprinzip:** Flache Hierarchie – von jedem Menüpunkt maximal 2 Taps zurück zum Hauptmenü. Bei einem Spiel mit kurzen 12-Minuten-Sessions darf das Meta-Menü selbst nicht viel Zeit kosten, sonst frisst es die knappe Spielzeit einer Pendel-Session auf.

**Charakterauswahl-Screen:** Horizontal swipbare Karten (ähnlich Punkt 3, aber ohne Zeitdruck), gesperrte Charaktere sind sichtbar aber ausgegraut mit Freischalt-Bedingung als Text darauf – motiviert durch "Vorschau aufs Ziel" statt es komplett zu verstecken

---

## 5. Sieg-/Niederlage-Screen (nach Run-Ende)

**Layout-Prinzip:** Zusammenfassung in absteigender Wichtigkeit für den Spieler:
1. Erreichte Zeit / Region-Fortschritt (großformatig, emotional wichtigster Wert)
2. Gold-Gewinn (mit kurzer Zähl-Animation, klassisches "befriedigendes" Genre-Element)
3. Getötete Gegner, erreichtes Charakter-Level (kleinere Sekundärwerte)
4. Button "Nochmal spielen" (primär, groß) vs. "Zum Menü" (sekundär, kleiner) – der primäre Button ist bewusst der mit dem höchsten Retention-Wert

---

## 6. Offene Punkte
- **Barrierefreiheits-Optionen** – ausgearbeitet: siehe `Barrierefreiheit_Tutorial_Bossfeedback_v0.1.md` (Teil 1)
- **Tutorial-Overlay** – ausgearbeitet: siehe `Barrierefreiheit_Tutorial_Bossfeedback_v0.1.md` (Teil 2)
- **Visuelles Feedback bei Boss-Phasenwechseln** – ausgearbeitet: siehe `Barrierefreiheit_Tutorial_Bossfeedback_v0.1.md` (Teil 3)
- **Reroll-Feature** – entschieden: 3 Gratis-Rerolls/Run, bis zu +2 über den Talent-Knoten „Wahrsagerei" (siehe §3 und Wirtschafts-Dokument)

→ Alle tuning-relevanten Punkte mit Startwert, Messgröße und Anpassungsregel: `Playtesting_Tuning_Plan_v0.1.md` (Abschnitt 5.4).
