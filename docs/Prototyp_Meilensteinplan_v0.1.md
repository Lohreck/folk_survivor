# Prototyp-Scope & Meilensteinplan
### Ergänzung zum GDD "Survivor-Like Mobile" v0.1

Hinweis: Grobe Phasenplanung ohne feste Zeitangaben (hängt von Teamgröße/Verfügbarkeit ab) – Fokus liegt auf **sinnvoller Reihenfolge und klaren Erfolgskriterien** pro Meilenstein, nicht auf einem Kalenderdatum.

---

## Grundprinzip der Reihenfolge

Größtes Risiko zuerst validieren (Mobile-Performance bei vielen Gegnern), dann den kleinstmöglichen spielbaren Loop bauen, danach erst in die Breite (Inhalt) gehen. Das vermeidet, dass viel Inhalt gebaut wird, der bei einem späten Performance- oder Spielgefühl-Problem wieder verworfen werden müsste.

---

## Meilenstein 0 – Technischer Risiko-Test

**Ziel:** Klären, ob der Kern-Ansatz (viele gleichzeitige Gegner auf Mobile) überhaupt performant umsetzbar ist, bevor irgendetwas anderes gebaut wird.

**Scope:**
- Object-Pooling-Grundgerüst (siehe Technisches Konzept, Punkt 3)
- Ein einzelner Platzhalter-Gegnertyp, 85 gleichzeitige Instanzen (Testpuffer bis 100)
- Kein Gameplay, keine Grafik – reiner Performance-Test auf echtem Mittelklasse-Android-Gerät

**Erfolgskriterium:** Stabile Framerate (Ziel: 60 FPS, mindestens akzeptabel bei 30 FPS) bei maximaler Gegnerzahl aus dem Balancing-Dokument
**Risiko bei Nicht-Erreichen:** Grundkonzept (Gegnerzahl) muss nach unten korrigiert werden – lieber jetzt erkennen als nach Wochen Content-Arbeit

---

## Meilenstein 1 – Minimaler Spielbarer Loop ("Grey-Box")

**Ziel:** Der Kern-Loop fühlt sich gut an, unabhängig von Grafik/Content.

**Scope:**
- Virtueller Joystick + Spielerbewegung
- 1 Waffe (Auto-Attack), 1 Passiv-Item
- 1 Gegnertyp (Platzhalter-Grafik reicht)
- Level-Up-Screen mit einfacher Auswahl
- Einfacher Timer, kein Sieg-/Niederlage-Screen nötig, nur Grundschleife spürbar

**Erfolgskriterium:** Internes Playtesting – fühlt sich das Ausweichen/Positionieren allein schon befriedigend an? (Klassischer Genre-Test: "Ist es fun, auch ohne Grafik/Content?")

---

## Meilenstein 2 – Vertikale Scheibe: Region 1 komplett

**Ziel:** Eine Region vollständig spielbar, von Anfang bis Boss – als Referenz-Qualitätsmaßstab für alle weiteren Regionen.

**Scope:**
- Alle Region-1-Gegner (Kikimora, Domovoi, Aitvaras) mit finaler oder Nahezu-finaler Grafik
- Leshy als vollständiger Boss (Terrain-Veränderungs-Mechanik)
- 2–3 Waffen + zugehörige Passiv-Items, inkl. mindestens 1 vollständige Evolution
- Ein Startcharakter final ausbalanciert (Holzfäller oder Soldat)
- `SpawnDirector` mit den Balancing-Werten aus dem Balancing-Dokument

**Erfolgskriterium:** Ein kompletter 12-Minuten-Run ist von Anfang bis Boss-Sieg/-Niederlage spielbar und macht Spaß – das ist der Moment, um erstes externes Playtesting-Feedback einzuholen (Freunde, kleine Testgruppe)

---

## Meilenstein 3 – Meta-Progression-Schleife

**Ziel:** Der "Ich will noch einen Run spielen"-Anreiz zwischen den Sessions ist spürbar.

**Scope:**
- Gold-Sammlung + Talentbaum (mindestens 2–3 Kategorien, siehe Wirtschafts-Dokument)
- Charakter-Freischaltung für mindestens 1 weiteren Charakter
- Speichersystem (lokal, siehe Technisches Konzept Punkt 6)
- Meta-Menü-UI (auch wenn visuell noch nicht final)
- Reroll (3/Lauf, GDD Core-Loop) und Pause-Button (UI-UX-Layout) – bewusst aus M2c verschoben (Entscheidung 2026-09-23)

**Erfolgskriterium:** Playtester spielen freiwillig mehrere Runs hintereinander, weil sie den nächsten Talentbaum-Kauf sehen wollen ("One more run"-Gefühl testbar)

---

## Meilenstein 4 – Inhalts-Ausbau (Regionen 2–4)

**Ziel:** Gesamtes Spiel inhaltlich vollständig gemäß GDD.

**Scope:**
- Regionen 2–4 mit allen Gegnern, Mini-Bossen, Hauptbossen (siehe Regionen-Dokument)
- Alle 5 Waffen + alle 5 Evolutionen final
- Alle 8 Charaktere final
- Vollständiger Talentbaum

**Hinweis:** Dieser Meilenstein ist der zeitlich umfangreichste – lässt sich gut parallelisieren (z. B. Grafik/Sound-Produktion parallel zur Balancing-Feinarbeit), sollte aber erst starten, wenn Meilenstein 2+3 zeigen, dass Kern-Loop und Meta-Progression tragen

---

## Meilenstein 5 – Monetarisierung & Store-Vorbereitung

**Ziel:** Technisch und inhaltlich bereit für einen Soft Launch.

**Scope:**
- AdMob-Integration (Rewarded Ads, siehe Technisches Konzept Punkt 9)
- Bernstein-Währung + mindestens Grundgerüst Battle Pass
- Store-Listing final (Icon, Screenshots, Beschreibung – siehe Store-Listing-Dokument)
- Erste Kosmetik-Items für IAP-Test

**Erfolgskriterium:** Alle Kern-Monetarisierungselemente funktionieren technisch fehlerfrei (Ad-Callbacks, Kauf-Flows) – Fokus liegt hier auf Stabilität, nicht auf finalem Preis-Tuning

---

## Meilenstein 6 – Soft Launch

**Ziel:** Echte Daten aus einem kleinen Markt sammeln, bevor global gelauncht wird.

**Scope:**
- Launch in 1–2 kleineren Testmärkten (Play Store erlaubt regionale Veröffentlichung)
- Analytics-Integration (Retention D1/D7/D30, Session-Länge, Monetarisierungs-Kennzahlen)
- Crash-Reporting aktiv

**Erfolgskriterium:** Retention- und Monetarisierungs-Kennzahlen liegen im branchenüblichen Rahmen für das Genre (Richtwerte müssten separat recherchiert werden) – erst danach globaler Launch mit Marketing-Budget sinnvoll

---

## Übersicht (kompakt)

| Meilenstein | Fokus | Wichtigstes Erfolgskriterium |
|---|---|---|
| 0 | Performance-Risiko | Stabile FPS bei Ziel-Gegnerzahl |
| 1 | Kern-Loop (Grey-Box) | Fühlt sich fun an, auch ohne Content |
| 2 | Region 1 komplett | Kompletter Run macht Spaß, erstes externes Feedback |
| 3 | Meta-Progression | "One more run"-Effekt messbar |
| 4 | Inhalts-Ausbau | Alle Regionen/Waffen/Charaktere final |
| 5 | Monetarisierung/Store | Technisch stabile Ad-/Kauf-Flows |
| 6 | Soft Launch | Retention/Monetarisierung im Zielrahmen |

---

## Offene Punkte
- Konkrete Zeitschätzung pro Meilenstein hängt von Teamgröße ab (nicht Teil dieses Grobplans)
- Playtesting-Gruppe für Meilenstein 2+3 muss organisiert werden (Freunde, Discord-Community, o. Ä.)
- Welche Testmärkte sich für den Soft Launch eignen (üblich: kleinere, aber repräsentative Märkte wie z. B. Kanada, Skandinavien, Philippinen – abhängig von Zielgruppe und Sprache)

→ Teststufen, Kennzahlen und Playtest-Ablauf: siehe `Playtesting_Tuning_Plan_v0.1.md` (Abschnitte 2, 3 & 6).
