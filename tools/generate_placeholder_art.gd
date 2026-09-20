extends SceneTree
## Generiert Platzhalter-Pixelart als PNG (res://assets/sprites/).
##
## Run: Godot --headless --path . -s tools/generate_placeholder_art.gd
##
## Bewusstcommitted im Repo: Die endgültige Art ersetzt diese Datei NICHT,
## aber die Raster-Definitionen (Zeichenrasten) bleiben als Referenz für die
## Silhouetten-Formen (Setting-Dokument §6: „Gegner klar über Umriss
## unterscheidbar"). Alles zeigt nach RECHTS (Spiel dreht per velocity.angle()).
##
## Lesbarkeits-Regeln (Feedback Playtest M2c):
##   – Spieler warm/grün, Gegner kalt/kontrastreich, Projektile hell
##   – dunkle Outline um jede Figur (Abheben vom dunklen Waldboden)
##   – Projekteil-Glow-Insel groß genug, um bei 320 px/s gelesen zu werden

const OUT := "res://assets/sprites/"

## Zeichenraste -> PNG. '.'/Leerzeichen = transparent, alles andere = Palette.
func _save(file: String, rows: Array, pal: Dictionary) -> void:
	var w := 0
	for row: String in rows:
		w = maxi(w, row.length())
	var h := rows.size()
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in h:
		var row: String = rows[y]
		for x in row.length():
			var key := row[x]
			if not pal.has(key):
				continue
			img.set_pixel(x, y, pal[key])
	img.save_png(OUT + file)
	print("geschrieben: ", file)


func _save_img(file: String, img: Image) -> void:
	img.save_png(OUT + file)
	print("geschrieben: ", file)


func _initialize() -> void:
	var dir := DirAccess.open("res://")
	dir.make_dir_recursive("assets/sprites")
	_save("player.png", PLAYER, PAL_PLAYER)
	_save("kikimora.png", KIKIMORA, PAL_KIKIMORA)
	_save("domovoi.png", DOMOVOI, PAL_DOMOVOI)
	_save("aitvaras.png", AITVARAS, PAL_AITVARAS)
	_save("enemy_projectile.png", PROJ, PAL_PROJ)
	_save("xp_gem.png", GEM, PAL_GEM)
	_save("leshy.png", _draw_leshy(48), PAL_LESHY)
	_save("tree.png", _draw_tree(24, 32), PAL_TREE)
	quit()


## ---------- Rasten ----------

const PLAYER := [
	"................",
	"......ooooo.....",
	".....ohhhhho....",
	".....ohhssho....",
	".....ohsssho....",
	"......osso......",
	"....occcccc o...",
	"...occchhccco...",
	"...occcgcggco...",
	"...occcgcggco...",
	"...occcgcggco...",
	"....occccBcco...",
	"....occccgcgo...",
	".....obbcbb o...",
	".....obbcbb o...",
	"................",
]
const PAL_PLAYER := {
	"o": Color(0.13, 0.11, 0.09),
	"g": Color(0.18, 0.32, 0.16),
	"h": Color(0.3, 0.48, 0.24),
	"c": Color(0.26, 0.44, 0.22),
	"s": Color(0.87, 0.69, 0.5),
	"e": Color(0.08, 0.08, 0.1),
	"B": Color(0.45, 0.32, 0.14),
	"b": Color(0.35, 0.24, 0.13),
}

const KIKIMORA := [
	"................",
	".....ooooo......",
	"....owwwwo......",
	"...owhwwhwo.....",
	"...owwwwwwo.....",
	"...owewewewo....",
	"...owwwwwwo.....",
	"...orrrrrro.....",
	"..orrrrrrrro....",
	"..orrwrwrwro....",
	"..orrrrrrrro....",
	"..or.rr.rr.o....",
	"..or.rr.rr.o....",
	"..or.rr.rr.o....",
	"..o...oo...o....",
	"................",
]
const PAL_KIKIMORA := {
	"o": Color(0.1, 0.1, 0.12),
	"w": Color(0.88, 0.86, 0.82),
	"h": Color(0.55, 0.55, 0.6),
	"e": Color(1.0, 0.25, 0.2),
	"r": Color(0.3, 0.36, 0.28),
}

const DOMOVOI := [
	"....o......o....",
	"....o......o....",
	"....oppppppo....",
	"...oppppppppo...",
	"...oppdppdppo...",
	"...oppppppppo...",
	"....oppppppo..s.",
	"....oppppppo.sm.",
	"...opppppppo.sm.",
	"...oppppppppo.m.",
	"....opppppppo.m.",
	"....opppppppo.m.",
	"....opp.oppo.m..",
	"....obb.obbo.m..",
	"................",
	"................",
]
const PAL_DOMOVOI := {
	"o": Color(0.1, 0.07, 0.13),
	"p": Color(0.42, 0.3, 0.6),
	"d": Color(0.9, 0.75, 1.0),
	"b": Color(0.28, 0.2, 0.4),
	"s": Color(0.75, 0.55, 0.3),
	"m": Color(0.8, 0.62, 1.0),
}

const AITVARAS := [
	"................",
	"..o..........o..",
	"..oo........oo..",
	"..oo........oo..",
	"..ooo......ooo..",
	"..orroo..oorro..",
	"..orrrroorrrro..",
	"...orrrrrrrro...",
	"....rrrrrrrr....",
	"....rerreeerr...",
	"....rrrrrrrr....",
	".....rrrrrr.....",
	"......rrrr......",
	".......rr.......",
	"................",
	"................",
]
const PAL_AITVARAS := {
	"o": Color(0.25, 0.1, 0.04),
	"r": Color(0.92, 0.45, 0.15),
	"e": Color(1.0, 0.95, 0.4),
}

const PROJ := [
	"............",
	"............",
	"...ppppp....",
	"..pqqqqqp...",
	".pqeeWWWqp..",
	".pqeWWWWep..",
	".pqeeWWWep..",
	"..pqqqqqp...",
	"...ppppp....",
	"............",
	"............",
	"............",
]
const PAL_PROJ := {
	"p": Color(0.35, 0.15, 0.45),
	"q": Color(0.72, 0.35, 0.9),
	"e": Color(1.0, 0.75, 1.0),
	"W": Color(1.0, 1.0, 1.0),
}

const GEM := [
	"............",
	".....cc.....",
	"....chcc....",
	"...chccC c..",
	"..chccCccC..",
	"...chccC c..",
	"....cccc....",
	".....cc.....",
	"............",
	"............",
	"............",
	"............",
]
const PAL_GEM := {
	"c": Color(0.3, 0.9, 1.0),
	"C": Color(0.75, 1.0, 1.0),
	"h": Color(0.15, 0.55, 0.75),
}

## Leshy + Baum prozedural (Kreise/Rechtecke reichen für Silhouetten-Test).
const PAL_LESHY := {
	"c": Color(0.14, 0.32, 0.16),
	"C": Color(0.24, 0.45, 0.2),
	"t": Color(0.34, 0.24, 0.13),
	"e": Color(1.0, 0.9, 0.35),
	"o": Color(0.08, 0.16, 0.08),
}

const PAL_TREE := {
	"c": Color(0.2, 0.4, 0.17),
	"C": Color(0.3, 0.52, 0.22),
	"t": Color(0.34, 0.23, 0.12),
	"o": Color(0.1, 0.14, 0.09),
}


## ---------- Prozedurale Raster ----------

func _draw_leshy(s: int) -> Array:
	var rows: Array = []
	for y in s:
		var row := ""
		for x in s:
			row += "."
		rows.append(row)
	# Krone: zwei überlappende Kreise dunkelgrün.
	_stamp_circle(rows, 24, 16, 13, "c")
	_stamp_circle(rows, 16, 20, 10, "c")
	_stamp_circle(rows, 32, 18, 10, "c")
	# Moos-Highlights.
	_stamp_circle(rows, 20, 11, 4, "C")
	_stamp_circle(rows, 28, 14, 3, "C")
	# Stamm/Rumpf.
	for y in range(26, s):
		for x in range(18, 30):
			_stamp_pixel(rows, x, y, "t")
	# Leuchtende Augen.
	_stamp_circle(rows, 19, 17, 2, "e")
	_stamp_circle(rows, 29, 17, 2, "e")
	return rows


func _draw_tree(w: int, h: int) -> Array:
	var rows: Array = []
	for y in h:
		var row := ""
		for x in w:
			row += "."
		rows.append(row)
	# Krone.
	_stamp_circle(rows, w / 2, h * 0.35, 8, "c")
	_stamp_circle(rows, w / 2 - 4, h * 0.42, 6, "C")
	# Stamm.
	for y in range(int(h * 0.55), h):
		for x in range(w / 2 - 2, w / 2 + 2):
			_stamp_pixel(rows, x, y, "t")
	return rows


func _stamp_circle(rows: Array, cx: int, cy: int, r: int, ch: String) -> void:
	for y in range(maxi(0, cy - r), mini(rows.size(), cy + r + 1)):
		for x in range(maxi(0, cx - r), mini(rows[0].length(), cx + r + 1)):
			if Vector2(x - cx, y - cy).length() <= r:
				_stamp_pixel(rows, x, y, ch)


func _stamp_pixel(rows: Array, x: int, y: int, ch: String) -> void:
	if y < 0 or y >= rows.size() or x < 0 or x >= rows[y].length():
		return
	rows[y] = rows[y].substr(0, x) + ch + rows[y].substr(x + 1)