# Wirtschaft & Gold-Kurven (Meta-Progression)
### Ergänzung zum GDD "Survivor-Like Mobile" v0.1

Hinweis: Auch hier gilt – **Grobgerüst**, kein finales Balancing. Ziel: plausible, testbare Startwerte.

---

## 1. Währungssystem

| Währung | Herkunft | Verwendung |
|---|---|---|
| **Gold** (Soft Currency) | Kills, Truhen, Boss-/Mini-Boss-Siege, Run-Abschluss-Bonus | Talentbaum, Charakter-Freischaltung (siehe Charakterliste) |
| **Bernstein** (Premium/Hard Currency) | Tägliche Belohnungen, Battle Pass, Echtgeld-Käufe | Kosmetik, Battle-Pass-Freischaltung, Zeit-Skip (optional) |

Bewusste Trennung: Gold bleibt rein spielinterner Fortschritt (kein Pay-to-Win-Risiko), Bernstein ist ausschließlich für Kosmetik/Zeitersparnis – deckt sich mit dem in Punkt 5 des GDD festgelegten Fairness-Prinzip.

---

## 2. Gold-Einnahmen pro Run

### 2.1 Basis-Formel
```
Run-Gold = (Kills × Ø-Gold-pro-Kill) + Truhen-Gold + Boss-Bonus + Überlebenszeit-Bonus
```

**Hinweis:** Ø-Gold-pro-Kill ist bewusst ein **Bruchteil** (0.06–0.30). Bei tausenden Kills pro Run (siehe Balancing-Dokument Punkt 3.1.1) summiert sich das erst zum Run-Gewinn – das entspricht dem Genre-Standard (viele Kills × kleiner Wert).

### 2.2 Richtwerte nach Region

| Region | Ø-Gold pro Kill | Ø Kills bei vollem Run (12 Min.) | Truhen-Gold (2–3 pro Run) | Boss-Bonus (Hauptboss) |
|---|---|---|---|---|
| 1. Dammerwald | 0.08 | ~1.900 | 15–25 je Truhe | 80 |
| 2. Sumpfmoor | 0.13 | ~2.500 | 20–35 je Truhe | 130 |
| 3. Dorf der Vergessenen | 0.15 | ~3.100 | 30–45 je Truhe | 200 |
| 4. Reich von Nav' | 0.22 | ~3.800 | 40–60 je Truhe | 320 |

→ Kill-Zahlen und Ø-Gold/Kill sind aus den Spawn-Kurven des Balancing-Dokuments (Punkt 3.1.1) hergeleitet. Die **Run-Gesamtsummen bleiben gegenüber dem ersten Entwurf praktisch gleich** – nur die Verteilung (viele Kills × kleiner Wert statt wenige Kills × großer Wert) entspricht jetzt dem Genre-Standard.

**Beispiel Region 2, vollständiger Run:** ~2.500 × 0.13 ≈ 325 Gold (Kills) + ~75 Gold (Truhen) + 130 (Boss) + 65 (Mini-Boss, ca. 50% des Hauptboss-Bonus) ≈ **595 Gold pro vollem Run**

### 2.3 Überlebenszeit-Bonus (bei Tod vor Run-Ende)
```
Anteiliger Bonus = (überlebte Minuten / 12) × Vollständiger-Run-Gold-Wert × 0.5
```
→ Spieler, die früh sterben, bekommen trotzdem etwas Gold (verhindert Frust-Spiralen), aber deutlich weniger als bei vollständigem Run – erhält den Anreiz, länger durchzuhalten.

---

## 3. Talentbaum – Kosten-Kurve

Klassische **exponentielle Kostenkurve** für dauerhafte Upgrades, damit frühe Stufen schnell erreichbar sind (Belohnungsgefühl in den ersten Tagen), späte Stufen aber echten Fortschritt über Wochen darstellen:

```
Kosten(Stufe n) = Basis-Kosten × 1.35^(n-1)
```

**Beispiel "Start-HP +5" (Basis-Kosten 50 Gold, 10 Stufen max.):**

| Stufe | Kosten (Gold) | Kumuliert |
|---|---|---|
| 1 | 50 | 50 |
| 2 | 68 | 118 |
| 3 | 91 | 209 |
| 5 | 166 | ~490 |
| 10 | 738 | ~3.200 |

→ Bei ~595 Gold/Run (Region 2, siehe oben) ist Stufe 5 nach ca. 1 Run erreichbar, Stufe 10 nach ca. 5–6 Runs – fühlt sich über eine Woche verteilt angemessen an (mehrere Runs pro Tag realistisch bei 12-Min-Sessions).

**Weitere Talentbaum-Kategorien (gleiche Kurvenlogik, unterschiedliche Basis-Kosten):**
- Gold-Rate +X% (Basis 80 Gold – bewusst teurer, da es sich selbst verstärkt/"snowballt")
- Drop-Chance für Truhen +X% (Basis 60 Gold)
- Start-Waffe-Level +1 (Basis 120 Gold – starker Vorteil, daher teurer)
- Start-Rerolls +1 (Basis 100 Gold, max. +2 Stufen – Komfort/Build-Konsistenz, siehe UI-Dokument)

---

## 4. Charakter-Freischaltung – Kosten-Übersicht

| Charakter | Gold-Kosten | Alternative (skill-basiert) |
|---|---|---|
| Kräuterfrau | 500 | 1x Rusalka besiegt |
| Waisenkind-Figur | – (nur Fortschritt) | Region 2 erreicht |
| Wanderpriesterin | – (nur Fortschritt) | Leshy besiegt |
| Jäger | 1.500 | Region 3 erreicht |
| Seelenhüter | – (nur Fortschritt) | Region 4 erreicht |
| Zorya-Priesterin | – (nur Fortschritt) | Chernobog besiegt |

→ Gemischtes Modell: manche Charaktere rein über Fortschritt (fühlt sich wie "Story-Belohnung" an), manche über Gold (für Spieler, die lieber grinden/zahlen statt spielerisch fortschreiten wollen)

---

## 5. Bernstein (Premium-Währung) – Verdienst-Richtwerte

| Quelle | Bernstein-Menge |
|---|---|
| Tägliches Login | 5–10 (Tag 1–6), 30 (Tag 7, wöchentlicher Bonus) |
| Wöchentliche Herausforderung | 20–40 |
| Battle-Pass-Level (Free Track) | 5 pro Level (ca. 50 Level/Saison) |
| Echtgeld (Referenzwert) | z. B. 100 Bernstein ≈ 0,99 €, mit üblichen Mengenrabatten bei größeren Paketen |

**Battle-Pass-Kosten (Referenz):** ca. 500–800 Bernstein pro Saison → bei rein kostenlosem Spielen über Login+Challenges realistisch nach ca. 3–4 Wochen erspielbar, was einen sanften Kaufanreiz für ungeduldige Spieler schafft, ohne Free-Spieler komplett auszuschließen.

---

## 6. Offene Punkte
- Exakte Anzahl/Timing der Truhen-Spawns pro Run (aktuell nur grob "2–3 pro Run" angenommen)
- Ob Gold-Rate-Talent einen Soft-Cap braucht, um Inflation über viele Spielwochen zu verhindern
- Battle-Pass-Preisgestaltung im Detail (Free vs. Premium Track, genaue Belohnungsliste)
- A/B-Testing-Bedarf für die 1.35er-Exponentialbasis – ggf. je nach früher Retention-Daten anpassen

→ Alle tuning-relevanten Punkte mit Startwert, Messgröße und Anpassungsregel: `Playtesting_Tuning_Plan_v0.1.md` (Abschnitt 5.3).
