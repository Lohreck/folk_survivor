extends SceneTree
## Prototyp-Art-Generator: atmosphärische Pixelart in Richtung Diablo 1 mit
## slawischem Folklore-Touch. Ersetzt die alten flachen Platzhalter-Raster.
##
## Run:  Godot --headless --path . -s tools/generate_placeholder_art.gd
## Dann: Godot --headless --path . --editor --quit        (Reimport + .uid)
## Dann: Godot --headless --path . -s tools/art_contact_sheet.gd
##
## Bewusstcommitted im Repo: Die endgültige Art ersetzt diese Datei NICHT,
## aber die Formen bleiben als Referenz für die Silhouetten
## (Setting-Dokument §6: „Gegner klar über Umriss unterscheidbar").
##
## Art-Direction:
##   – gedämpfte, entsättigte Palette; warme Glut-Akzente (Augen, Feuer),
##     Leinen-/Knochen-Töne, Stickerei-Rot (slawische Folklore)
##   – Licht von oben (helle Oberkante, kühler Schatten unten), Checker-
##     Dithering an den Verlaufsübergängen, automatische dunkle Outline
##   – Textur statt Flächen (Rauschen, Stoff-, Stroh-, Rinden-Muster)
##
## Ausrichtung: Figuren stehen AUFRECHT und blicken dem Betrachter zu.
## player.gd/test_enemy.gd spiegeln per flip_h (früher: Rotation nach
## velocity.angle() – Wetterfahnen-Effekt). Waffen/Projektile rotieren weiter.

const OUT := "res://assets/sprites/"
const OUTLINE := Color(0.035, 0.032, 0.04)


## Material ableiten: warmes Licht oben, kühler Schatten unten.
func _mat(base: Color) -> Dictionary:
	return {
		"base": base,
		"hi": base.lightened(0.18).lerp(Color(1.0, 0.93, 0.80), 0.30),
		"lo": base.darkened(0.38).lerp(Color(0.10, 0.12, 0.18), 0.30),
	}


func _flat(c: Color) -> Dictionary:
	return {"flat": c}


## Raster -> PNG mit Outline + vertikaler Material-Schattierung (Licht oben).
func _render(file: String, rows: Array, mats: Dictionary, shade: bool = true, outline: bool = true) -> void:
	var w := (rows[0] as String).length()
	var h := rows.size()
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in h:
		var row: String = rows[y]
		for x in row.length():
			var key := row[x]
			if not mats.has(key):
				continue
			var m: Dictionary = mats[key]
			img.set_pixel(x, y, m.get("flat", m.get("base", Color(0, 0, 0, 1))))

	# Vertikaler Verlauf pro Material (Buchstaben-Bounding-Box als Referenz).
	if shade:
		var bbox := {}
		for y in h:
			var row: String = rows[y]
			for x in row.length():
				if img.get_pixel(x, y).a == 0.0:
					continue
				var m: Dictionary = mats.get(row[x], {})
				if m.has("flat"):
					continue
				var b: Array = bbox.get(row[x], [y, y])
				b[0] = mini(b[0], y)
				b[1] = maxi(b[1], y)
				bbox[row[x]] = b
		for y in h:
			var row: String = rows[y]
			for x in row.length():
				var key := row[x]
				if not bbox.has(key):
					continue
				var m: Dictionary = mats[key]
				var b: Array = bbox[key]
				var t := 0.5 if b[1] == b[0] else float(y - b[0]) / float(b[1] - b[0])
				var alt := (x + y) % 2 == 0
				var col: Color = m["base"]
				if (t < 0.28 and (alt or t < 0.20)) or (t >= 0.20 and t < 0.28 and alt):
					col = m["hi"]
				elif (t > 0.70 and (alt or t > 0.78)) or (t > 0.62 and t <= 0.70 and alt):
					col = m["lo"]
				img.set_pixel(x, y, col)

	# Automatische dunkle Outline um jede Figur (Abheben vom dunklen Boden).
	if outline:
		var add: Array = []
		for y in h:
			for x in w:
				if img.get_pixel(x, y).a != 0.0:
					continue
				var near := false
				for n in [Vector2i(x - 1, y), Vector2i(x + 1, y), Vector2i(x, y - 1), Vector2i(x, y + 1)]:
					if n.x >= 0 and n.x < w and n.y >= 0 and n.y < h and img.get_pixel(n.x, n.y).a > 0.0:
						near = true
						break
				if near:
					add.append(Vector2i(x, y))
		for p: Vector2i in add:
			img.set_pixel(p.x, p.y, OUTLINE)

	img.save_png(OUT + file)
	print("geschrieben: ", file, " (", w, "x", h, ")")


func _initialize() -> void:
	var dir := DirAccess.open("res://")
	dir.make_dir_recursive("assets/sprites")
	_gen_player()
	_gen_kikimora()
	_gen_domovoi()
	_gen_aitvaras()
	_gen_leshy()
	_gen_tree()
	_gen_gem()
	_gen_proj()
	_gen_ground()
	quit()


## ---------- Zeichen-Helfer (alle auf fixes Längen-Raster) ----------

func _blank(w: int, h: int) -> Array:
	var rows: Array = []
	for y in h:
		rows.append(".".repeat(w))
	return rows


func _stamp_pixel(rows: Array, x: int, y: int, ch: String) -> void:
	if y < 0 or y >= rows.size() or x < 0 or x >= rows[y].length():
		return
	rows[y] = rows[y].substr(0, x) + ch + rows[y].substr(x + 1)


func _stamp_rect(rows: Array, x0: int, y0: int, x1: int, y1: int, ch: String) -> void:
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			_stamp_pixel(rows, x, y, ch)


func _stamp_ellipse(rows: Array, cx: int, cy: int, rx: int, ry: int, ch: String) -> void:
	for y in range(cy - ry, cy + ry + 1):
		for x in range(cx - rx, cx + rx + 1):
			var dx := float(x - cx) / float(maxi(rx, 1))
			var dy := float(y - cy) / float(maxi(ry, 1))
			if dx * dx + dy * dy <= 1.05:
				_stamp_pixel(rows, x, y, ch)


func _stamp_line(rows: Array, x0: int, y0: int, x1: int, y1: int, ch: String) -> void:
	var dx := absi(x1 - x0)
	var dy := -absi(y1 - y0)
	var sx := 1 if x0 < x1 else -1
	var sy := 1 if y0 < y1 else -1
	var err := dx + dy
	while true:
		_stamp_pixel(rows, x0, y0, ch)
		if x0 == x1 and y0 == y1:
			break
		var e2 := 2 * err
		if e2 >= dy:
			err += dy
			x0 += sx
		if e2 <= dx:
			err += dx
			y0 += sy


## Zerfetzter Saum (z. B. zerlumpte Hemden, Strohrock).
func _hem(rows: Array, y: int, x0: int, x1: int, prob: float, rng: RandomNumberGenerator) -> void:
	for x in range(x0, x1 + 1):
		if rng.randf() < prob:
			_stamp_pixel(rows, x, y, ".")
			if rng.randf() < 0.5:
				_stamp_pixel(rows, x, y + 1, ".")


## Nur Buchstaben aus `from` innerhalb des Rechtecks durch `to` ersetzen.
func _speckle(rows: Array, x0: int, y0: int, x1: int, y1: int, from: String, to: String, prob: float, rng: RandomNumberGenerator) -> void:
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			if y < 0 or y >= rows.size() or x < 0 or x >= rows[y].length():
				continue
			if from.find(rows[y][x]) >= 0 and rng.randf() < prob:
				_stamp_pixel(rows, x, y, to)


## ---------- Spieler: Waldwanderer mit Kapuze + Stickerei ----------

func _gen_player() -> void:
	var r := _blank(24, 24)
	# Torso/Schultern (Mantel).
	_stamp_rect(r, 7, 10, 15, 19, "c")
	_stamp_rect(r, 6, 9, 16, 11, "c")
	# Ärmel (dunklerer Ton) + Armtrennung durch eigenen Buchstaben.
	_stamp_rect(r, 5, 11, 6, 18, "a")
	_stamp_rect(r, 16, 11, 17, 18, "a")
	# Kapuze.
	_stamp_ellipse(r, 11, 5, 5, 4, "c")
	_stamp_rect(r, 6, 5, 16, 6, "c")
	# Gesicht im Kuzen-Schatten.
	_stamp_rect(r, 9, 6, 13, 9, "s")
	_stamp_pixel(r, 11, 8, "n")  # Nasenschatten
	_stamp_pixel(r, 10, 7, "e")
	_stamp_pixel(r, 12, 7, "e")
	# Leinen-Leibchen + rote Kreuzstich-Glyphen (slawische Folklore).
	_stamp_rect(r, 10, 10, 12, 14, "l")
	for p: Array in [[11, 10], [10, 12], [12, 12], [11, 14]]:
		_stamp_pixel(r, p[0], p[1], "r")
	# Gürtel + Messingschnalle.
	_stamp_rect(r, 7, 15, 15, 16, "b")
	_stamp_pixel(r, 11, 15, "m")
	_stamp_pixel(r, 11, 16, "m")
	# Stiefel.
	_stamp_rect(r, 7, 20, 9, 22, "t")
	_stamp_rect(r, 13, 20, 15, 22, "t")
	# Zerfetzter Saum.
	var rng := RandomNumberGenerator.new()
	rng.seed = 101
	_hem(r, 19, 7, 15, 0.30, rng)
	_render("player.png", r, {
		"c": _mat(Color(0.20, 0.30, 0.16)),       # Mantelgrün
		"a": _mat(Color(0.16, 0.25, 0.13)),       # Ärmel dunkler
		"s": _mat(Color(0.72, 0.56, 0.42)),       # Haut
		"n": _mat(Color(0.55, 0.42, 0.31)),       # Hautschatten
		"l": _mat(Color(0.60, 0.55, 0.42)),       # Leinen
		"b": _mat(Color(0.30, 0.21, 0.13)),       # Leder
		"t": _mat(Color(0.22, 0.16, 0.11)),       # Stiefel
		"e": _flat(Color(0.07, 0.06, 0.06)),
		"r": _flat(Color(0.60, 0.14, 0.11)),      # Stickerei-Rot
		"m": _flat(Color(0.74, 0.60, 0.30)),      # Messing
	})


## ---------- Kikimora: Strohpuppe aus dem Sumpf ----------

func _gen_kikimora() -> void:
	var r := _blank(24, 24)
	# Rock (Stroh), drei Ebenen mit Saum.
	_stamp_rect(r, 8, 8, 14, 10, "s")
	_stamp_rect(r, 7, 11, 15, 14, "s")
	_stamp_rect(r, 6, 15, 16, 19, "s")
	# Kopf (Knochenweiß).
	_stamp_ellipse(r, 11, 5, 4, 3, "h")
	# Stroh-Am locken seitlich.
	_stamp_rect(r, 6, 4, 6, 7, "y")
	_stamp_rect(r, 16, 4, 16, 7, "y")
	_stamp_pixel(r, 5, 5, "x")
	_stamp_pixel(r, 17, 5, "x")
	# Leere Augen + gestickter Mund.
	_stamp_pixel(r, 9, 5, "e")
	_stamp_pixel(r, 13, 5, "e")
	for x in [9, 11, 13]:
		_stamp_pixel(r, x, 7, "e")
	for x in [10, 12]:
		_stamp_pixel(r, x, 7, "r")
	# Rothfaden-Gürtel (gepunktet).
	for x in [7, 9, 11, 13, 15]:
		_stamp_pixel(r, x, 13, "r")
	# Moos am Saum.
	for p: Array in [[7, 19], [8, 18], [14, 18], [15, 19]]:
		_stamp_pixel(r, p[0], p[1], "m")
	# Ärmchen/Beinchen aus Twigs.
	_stamp_line(r, 7, 10, 5, 15, "t")
	_stamp_line(r, 15, 10, 17, 15, "t")
	_stamp_rect(r, 9, 20, 10, 21, "t")
	_stamp_rect(r, 12, 20, 13, 21, "t")
	# Strohtextur + zerfetzter Rocksaum.
	var rng := RandomNumberGenerator.new()
	rng.seed = 202
	_speckle(r, 6, 8, 16, 19, "s", "x", 0.16, rng)
	_speckle(r, 6, 8, 16, 19, "s", "y", 0.10, rng)
	_hem(r, 19, 6, 16, 0.35, rng)
	_render("kikimora.png", r, {
		"s": _mat(Color(0.72, 0.62, 0.36)),       # Stroh
		"x": _mat(Color(0.52, 0.44, 0.25)),       # Stroh dunkel
		"y": _mat(Color(0.84, 0.74, 0.47)),       # Stroh hell
		"h": _mat(Color(0.74, 0.70, 0.59)),       # Knochen
		"t": _mat(Color(0.34, 0.26, 0.18)),       # Stockholz
		"m": _mat(Color(0.34, 0.44, 0.26)),       # Moos
		"e": _flat(Color(0.09, 0.08, 0.07)),
		"r": _flat(Color(0.66, 0.16, 0.12)),
	})


## ---------- Domovoi (verdorben): Hausgeist mitGlut-Augen ----------

func _gen_domovoi() -> void:
	var r := _blank(24, 24)
	# Kutte (bauchig).
	_stamp_rect(r, 5, 11, 17, 18, "p")
	_stamp_rect(r, 6, 9, 16, 11, "p")
	_stamp_rect(r, 6, 19, 16, 19, "p")
	# Hörner.
	_stamp_line(r, 9, 3, 8, 0, "H")
	_stamp_line(r, 13, 3, 14, 0, "H")
	# Kopf.
	_stamp_ellipse(r, 11, 6, 5, 3, "f")
	# Stirnbrauen +Glut-Augen.
	for x in [9, 10]:
		_stamp_pixel(r, x, 5, "e")
	for x in [12, 13]:
		_stamp_pixel(r, x, 5, "e")
	_stamp_pixel(r, 9, 6, "E")
	_stamp_pixel(r, 13, 6, "E")
	# Bart (grau, spitz zulaufend).
	_stamp_rect(r, 8, 8, 14, 9, "v")
	_stamp_rect(r, 9, 10, 13, 11, "v")
	_stamp_rect(r, 10, 12, 12, 12, "v")
	_stamp_pixel(r, 11, 13, "v")
	# Gürtel.
	_stamp_rect(r, 5, 16, 17, 16, "b")
	_stamp_pixel(r, 11, 16, "m")
	# Rechte Hand hält Schöpfkelle (Fernkampf-Andeutung).
	_stamp_line(r, 17, 12, 19, 10, "p")
	_stamp_line(r, 19, 10, 21, 9, "w")
	_stamp_ellipse(r, 21, 8, 2, 2, "w")
	# Linker Arm hängt.
	_stamp_rect(r, 4, 12, 5, 17, "p")
	# Stummel-Beine + Füße.
	_stamp_rect(r, 7, 20, 9, 21, "p")
	_stamp_rect(r, 13, 20, 15, 21, "p")
	_stamp_rect(r, 7, 22, 9, 23, "t")
	_stamp_rect(r, 13, 22, 15, 23, "t")
	# Textur +Saum.
	var rng := RandomNumberGenerator.new()
	rng.seed = 303
	_speckle(r, 5, 9, 17, 21, "p", "q", 0.18, rng)
	_speckle(r, 8, 8, 14, 12, "v", "Q", 0.15, rng)
	_hem(r, 19, 6, 16, 0.40, rng)
	_render("domovoi.png", r, {
		"p": _mat(Color(0.50, 0.38, 0.55)),       # Grauviolette Kutte
		"q": _mat(Color(0.40, 0.30, 0.44)),       # Lappen dunkel
		"f": _mat(Color(0.62, 0.56, 0.50)),       # Gesicht
		"v": _mat(Color(0.70, 0.66, 0.61)),       # Bart
		"Q": _mat(Color(0.56, 0.52, 0.48)),       # Bart dunkel
		"H": _mat(Color(0.68, 0.62, 0.52)),       # Hörner
		"w": _mat(Color(0.55, 0.40, 0.23)),       # Holz
		"b": _mat(Color(0.40, 0.29, 0.18)),
		"t": _mat(Color(0.33, 0.24, 0.15)),
		"e": _flat(Color(0.13, 0.10, 0.08)),
		"E": _flat(Color(1.0, 0.70, 0.24)),       #Glut
		"m": _flat(Color(0.80, 0.66, 0.34)),
	})


## ---------- Aitvaras: baltischer Hausgeist-Drache ----------

func _gen_aitvaras() -> void:
	var r := _blank(24, 24)
	# Flügel: Oberkante als Diagonale, unten gezackt (Scallops).
	for x in range(1, 9):
		var top := int(round(7.0 - float(8 - x) * 0.42))
		var bot: int
		if x <= 2:
			bot = 13
		elif x <= 4:
			bot = 12
		elif x <= 6:
			bot = 11
		else:
			bot = 10
		for y in range(top, bot + 1):
			_stamp_pixel(r, x, y, "w")
	for x in range(14, 22):
		var top := int(round(7.0 - float(x - 14) * 0.42))
		var mx := 22 - x  # gespiegelte linke Spalte
		var bot: int
		if mx <= 2:
			bot = 13
		elif mx <= 4:
			bot = 12
		elif mx <= 6:
			bot = 11
		else:
			bot = 10
		for y in range(top, bot + 1):
			_stamp_pixel(r, x, y, "w")
	# Fingerknochen als Strahlen zur Schulter.
	_stamp_line(r, 8, 7, 1, 4, "n")
	_stamp_line(r, 8, 8, 3, 12, "n")
	_stamp_line(r, 8, 8, 7, 10, "n")
	_stamp_line(r, 14, 7, 21, 4, "n")
	_stamp_line(r, 14, 8, 19, 12, "n")
	_stamp_line(r, 14, 8, 15, 10, "n")
	# Körper + Kopf.
	_stamp_rect(r, 9, 7, 13, 16, "b")
	_stamp_ellipse(r, 11, 5, 3, 2, "b")
	# Hörner.
	_stamp_line(r, 9, 3, 8, 0, "b")
	_stamp_line(r, 13, 3, 14, 0, "b")
	#Glut-Augen + glühender Rachen.
	_stamp_pixel(r, 10, 5, "E")
	_stamp_pixel(r, 12, 5, "E")
	_stamp_pixel(r, 11, 8, "F")
	_stamp_pixel(r, 12, 8, "F")
	# Schwanz mit stumpfem Ende.
	_stamp_rect(r, 11, 17, 12, 20, "b")
	_stamp_rect(r, 10, 21, 13, 22, "b")
	_stamp_pixel(r, 10, 21, ".")
	_stamp_pixel(r, 13, 21, ".")
	# Krallen.
	_stamp_line(r, 10, 17, 9, 19, "n")
	_stamp_line(r, 13, 17, 14, 19, "n")
	# Flügelmembran-Textur.
	var rng := RandomNumberGenerator.new()
	rng.seed = 404
	_speckle(r, 1, 4, 21, 13, "w", "W", 0.14, rng)
	_render("aitvaras.png", r, {
		"b": _mat(Color(0.30, 0.21, 0.16)),       # Körper
		"w": _mat(Color(0.74, 0.36, 0.14)),       # Membran
		"W": _mat(Color(0.58, 0.27, 0.10)),       # Membran dunkel
		"n": _mat(Color(0.44, 0.31, 0.21)),       # Knochen
		"E": _flat(Color(1.0, 0.84, 0.40)),
		"F": _flat(Color(1.0, 0.60, 0.18)),
	})


## ---------- Leshy: Waldherr mit Asten-Hörnern (64x64) ----------

func _gen_leshy() -> void:
	var s := 64
	var r := _blank(s, s)
	# Rumpf mit gezackter Rindenkante (symmetrisch um x=32).
	_stamp_rect(r, 21, 26, 43, 58, "k")
	_stamp_rect(r, 24, 20, 40, 26, "k")
	for y in range(26, 59):
		var cut := 2 if (y * 7 + 3) % 5 < 3 else 1
		for i in cut:
			_stamp_pixel(r, 21 + i, y, ".")
			_stamp_pixel(r, 43 - i, y, ".")
	# Kopf.
	_stamp_ellipse(r, 32, 15, 11, 8, "k")
	# Maske/Gesichtsparte heller.
	_stamp_ellipse(r, 32, 17, 7, 5, "K")
	# Bogenbrauen (wütend).
	_stamp_line(r, 24, 13, 29, 14, "b")
	_stamp_line(r, 40, 13, 35, 14, "b")
	#Glut-Augen.
	_stamp_rect(r, 26, 15, 28, 16, "E")
	_stamp_rect(r, 36, 15, 38, 16, "E")
	_stamp_rect(r, 27, 15, 27, 16, "F")
	_stamp_rect(r, 37, 15, 37, 16, "F")
	# Ast-Hörner.
	_stamp_line(r, 25, 8, 15, 2, "A")
	_stamp_line(r, 20, 5, 17, 8, "A")
	_stamp_line(r, 17, 3, 14, 6, "A")
	_stamp_line(r, 39, 8, 49, 2, "A")
	_stamp_line(r, 44, 5, 47, 8, "A")
	_stamp_line(r, 47, 3, 50, 6, "A")
	#Moos-Krone.
	var rng := RandomNumberGenerator.new()
	rng.seed = 505
	_speckle(r, 23, 8, 41, 16, "k", "m", 0.35, rng)
	_speckle(r, 24, 6, 40, 12, "K", "m", 0.30, rng)
	# Arme (dicke Äste mit Klauen).
	_stamp_line(r, 22, 30, 9, 42, "k")
	_stamp_line(r, 23, 31, 10, 43, "k")
	_stamp_line(r, 9, 42, 6, 47, "k")
	_stamp_line(r, 9, 42, 10, 48, "k")
	_stamp_line(r, 42, 30, 55, 42, "k")
	_stamp_line(r, 41, 31, 54, 43, "k")
	_stamp_line(r, 55, 42, 58, 47, "k")
	_stamp_line(r, 55, 42, 54, 48, "k")
	# Wurzel-Beine + Basis-Mulde.
	_stamp_line(r, 27, 56, 23, 63, "k")
	_stamp_line(r, 37, 56, 41, 63, "k")
	_stamp_ellipse(r, 32, 61, 15, 3, "g")
	# Birkenflecken (slawischer Wald) mit dunklen Strichen.
	_stamp_rect(r, 25, 30, 29, 40, "w")
	_stamp_rect(r, 36, 34, 39, 43, "w")
	for p: Array in [[26, 32], [28, 36], [27, 39], [37, 37], [38, 41], [36, 43]]:
		_stamp_rect(r, p[0], p[1], p[0] + 1, p[1], "d")
	# Rinden-Textur: vertikale Streben.
	for y in range(20, 60):
		for x in range(9, 56):
			var c := (r[y] as String)[x]
			if c != "k" and c != "K":
				continue
			if (x * 7 + y * 3) % 11 == 0:
				_stamp_pixel(r, x, y, "t")
			elif (x * 3 + y * 5) % 13 == 0:
				_stamp_pixel(r, x, y, "T")
	_render("leshy.png", r, {
		"k": _mat(Color(0.32, 0.26, 0.19)),       # Rinde
		"K": _mat(Color(0.40, 0.33, 0.24)),       # Rinde hell (Maske)
		"t": _mat(Color(0.22, 0.17, 0.12)),       # Rinde dunkel
		"T": _mat(Color(0.48, 0.40, 0.29)),       # Rinde hell
		"b": _mat(Color(0.20, 0.15, 0.10)),       # Brauen
		"A": _mat(Color(0.56, 0.50, 0.40)),       # Ast-Hörner
		"m": _mat(Color(0.27, 0.38, 0.21)),       # Moos
		"g": _mat(Color(0.18, 0.26, 0.15)),       #Moos dunkel (Basis)
		"w": _mat(Color(0.66, 0.64, 0.55)),       # Birke
		"d": _flat(Color(0.10, 0.09, 0.08)),      # Birken-Striche
		"E": _flat(Color(1.0, 0.72, 0.28)),
		"F": _flat(Color(1.0, 0.92, 0.55)),
	})


func rows_size(r: Array) -> int:
	return r.size()


## ---------- Baum: dunkle Nadel-Silhouette (Terrain-Hazard) ----------

func _gen_tree() -> void:
	var w := 24
	var h := 32
	var r := _blank(w, h)
	var rng := RandomNumberGenerator.new()
	rng.seed = 606
	# Drei Sprössse (Kegelstufen).
	var tiers: Array = [[3, 12, 10], [9, 20, 8], [15, 27, 6]]
	for t: Array in tiers:
		for y in range(t[0], t[1] + 1):
			var prog := float(y - t[0]) / float(maxi(t[1] - t[0], 1))
			var hw := 1.0 + prog * float(t[2]) * 0.5
			for x in range(12 - int(hw), 12 + int(hw) + 1):
				# Zackige Kante.
				var edge := absf(float(x) - 11.5) > hw - 0.9
				if edge and rng.randf() < 0.45:
					continue
				_stamp_pixel(r, x, y, "n")
	# Stamm.
	_stamp_rect(r, 10, 27, 13, 31, "t")
	# Innere Verdunkelung + Nadeln-Textur.
	_speckle(r, 2, 3, 21, 27, "n", "N", 0.30, rng)
	_render("tree.png", r, {
		"n": _mat(Color(0.15, 0.20, 0.14)),       # Nadeln
		"N": _mat(Color(0.10, 0.14, 0.10)),       # Nadeln innen
		"t": _mat(Color(0.26, 0.19, 0.12)),       # Stamm
	})


## ---------- XP-Seele: kalter Irrlicht-Granat ----------

func _gen_gem() -> void:
	var s := 12
	var r := _blank(s, s)
	for y in s:
		for x in s:
			var dx := absf(float(x) - 5.5) / 5.5
			var dy := absf(float(y) - 5.5) / 5.5
			var d := dx + dx * 0.2 + dy  #Raute
			if d > 1.05:
				continue
			if d > 0.80:
				_stamp_pixel(r, x, y, "r")
			elif d > 0.45:
				_stamp_pixel(r, x, y, "m")
			else:
				_stamp_pixel(r, x, y, "c")
	# Funkeln.
	_stamp_pixel(r, 4, 3, "h")
	_stamp_pixel(r, 5, 4, "h")
	_render("xp_gem.png", r, {
		"r": _mat(Color(0.10, 0.30, 0.36)),       # Rim
		"m": _mat(Color(0.22, 0.62, 0.68)),       # Kern-Mitte
		"c": _flat(Color(0.75, 1.0, 1.0)),        # heißer Kern
		"h": _flat(Color(1.0, 1.0, 1.0)),
	}, true, true)


## ---------- Feindprojektil: verdorbenerGlutfunke (16x16) ----------

func _gen_proj() -> void:
	var s := 16
	var r := _blank(s, s)
	var c := (s - 1) / 2.0
	for y in s:
		for x in s:
			var d := Vector2(float(x) - c, float(y) - c).length()
			if d > 6.6:
				continue
			var band: String
			if d > 5.2:
				band = "r"
			elif d > 3.6:
				band = "m"
			elif d > 2.2:
				band = "h"
			else:
				band = "c"
			# Dither an den Bandgrenzen (Checker auf der jeweils äußeren Seite).
			var alt := (x + y) % 2 == 0
			if alt and d > 5.2 and d <= 5.8:
				band = "m"
			elif alt and d > 3.6 and d <= 4.2:
				band = "h"
			elif alt and d > 2.2 and d <= 2.8:
				band = "c"
			_stamp_pixel(r, x, y, band)
	_stamp_pixel(r, 6, 6, "c")
	_render("enemy_projectile.png", r, {
		"r": _mat(Color(0.24, 0.12, 0.06)),       #Rand (dunkel)
		"m": _mat(Color(0.85, 0.45, 0.16)),       # Glut
		"h": _flat(Color(1.0, 0.80, 0.45)),
		"c": _flat(Color(1.0, 0.97, 0.88)),
	}, false, true)


## ---------- Waldboden: nahtlose64x64-Kachel (Diablo-Böden) ----------

func _gen_ground() -> void:
	var s := 64
	var r := _blank(s, s)
	var rng := RandomNumberGenerator.new()
	rng.seed = 707
	# Grundfläche.
	for y in s:
		for x in s:
			_stamp_pixel(r, x, y, "b")
	# Große Erd-Flecken (billineares Value-Noise, nahtlos über den Kachelrand).
	var cells := 8
	var grid: Array = []
	for i in cells * cells:
		grid.append(rng.randf())
	var gf := float(s) / float(cells)
	for y in s:
		for x in s:
			var fx := float(x) / gf
			var fy := float(y) / gf
			var x0 := int(floor(fx))
			var y0 := int(floor(fy))
			var x1 := (x0 + 1) % cells
			var y1 := (y0 + 1) % cells
			var tx := fx - floorf(fx)
			var ty := fy - floorf(fy)
			tx = tx * tx * (3.0 - 2.0 * tx)
			ty = ty * ty * (3.0 - 2.0 * ty)
			var top: float = lerp(grid[y0 * cells + x0], grid[y0 * cells + x1], tx)
			var bot: float = lerp(grid[y1 * cells + x0], grid[y1 * cells + x1], tx)
			var v: float = (lerp(top, bot, ty) - 0.5) * 1.9 + 0.5
			if v > 0.72:
				_stamp_pixel(r, x, y, "D")
			elif v < 0.28:
				_stamp_pixel(r, x, y, "c")
	# Wurzeln (Random Walks, wrap-fähig).
	for i in 4:
		var wx := rng.randi_range(0, s - 1)
		var wy := rng.randi_range(0, s - 1)
		var ang := rng.randf() * TAU
		for step in rng.randi_range(18, 34):
			_stamp_pixel_wrap(r, wx, wy, "R", s)
			ang += rng.randf_range(-0.7, 0.7)
			wx = wrapi(wx + int(round(cos(ang))), 0, s)
			wy = wrapi(wy + int(round(sin(ang))), 0, s)
	# Tote Blätter als kleine Flocken.
	for i in 10:
		var lx := rng.randi_range(0, s - 1)
		var ly := rng.randi_range(0, s - 1)
		_stamp_pixel_wrap(r, lx, ly, "L", s)
		_stamp_pixel_wrap(r, lx + 1, ly, "L", s)
		_stamp_pixel_wrap(r, lx, ly + 1, "L", s)
	# Moosinseln.
	for i in 5:
		var mx := rng.randi_range(0, s - 1)
		var my := rng.randi_range(0, s - 1)
		for dy in range(-2, 3):
			for dx in range(-2, 3):
				if Vector2(dx, dy).length() <= 2.1 and rng.randf() < 0.8:
					_stamp_pixel_wrap(r, mx + dx, my + dy, "M", s)
	# Steine.
	for i in 3:
		var sx := rng.randi_range(0, s - 1)
		var sy := rng.randi_range(0, s - 1)
		for dy in range(-1, 2):
			for dx in range(-2, 3):
				if Vector2(float(dx) / 2.0, float(dy)).length() <= 1.2:
					_stamp_pixel_wrap(r, sx + dx, sy + dy, "S", s)
		_stamp_pixel_wrap(r, sx - 1, sy - 1, "s", s)
	# Feines Korn.
	for y in s:
		for x in s:
			if rng.randf() < 0.06:
				var cur := (r[y] as String)[x]
				if cur == "b":
					_stamp_pixel(r, x, y, "k" if rng.randf() < 0.5 else "c")
	_render("ground.png", r, {
		"b": _flat(Color(0.19, 0.17, 0.13)),      # Erde
		"D": _flat(Color(0.155, 0.14, 0.115)),    # feuchte Stelle
		"c": _flat(Color(0.225, 0.20, 0.155)),    # trockene Erde
		"k": _flat(Color(0.16, 0.14, 0.11)),
		"L": _flat(Color(0.245, 0.185, 0.115)),   #Laub
		"M": _flat(Color(0.16, 0.21, 0.13)),      # Moos
		"R": _flat(Color(0.23, 0.17, 0.11)),      # Wurzel
		"S": _flat(Color(0.21, 0.203, 0.185)),    # Stein
		"s": _flat(Color(0.235, 0.228, 0.21)),    # Steinlicht
	}, false, false)


func _stamp_pixel_wrap(rows: Array, x: int, y: int, ch: String, size: int) -> void:
	_stamp_pixel(rows, wrapi(x, 0, size), wrapi(y, 0, size), ch)
