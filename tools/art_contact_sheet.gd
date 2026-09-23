extends SceneTree
## Kontaktbogen: alle Sprites vergrössert (x6, nearest) auf dunklem Grund,
## damit Art-Iterationen visuell beurteilt werden können.
##
## Run: Godot --headless --path . -s tools/art_contact_sheet.gd
## Ausgabe: <Temp-Ordner>/shots/art_sheet.png (Reihenfolge siehe Print).

const FILES := [
	"player", "kikimora", "domovoi", "aitvaras",
	"leshy", "tree", "xp_gem", "enemy_projectile", "ground",
]
const SCALE := 6
const PAD := 14
const COLS := 4


func _initialize() -> void:
	var imgs: Array[Image] = []
	var max_w := 0
	var max_h := 0
	for f in FILES:
		var img := Image.new()
		var path := ProjectSettings.globalize_path("res://assets/sprites/%s.png" % f)
		if img.load(path) != OK:
			print("FEHLER: nicht geladen: ", f)
			quit(1)
			return
		imgs.append(img)
		max_w = maxi(max_w, img.get_width())
		max_h = maxi(max_h, img.get_height())

	var cell_w := max_w * SCALE + PAD
	var cell_h := max_h * SCALE + PAD
	var rows := ceili(imgs.size() / float(COLS))
	var sheet := Image.create(COLS * cell_w + PAD, rows * cell_h + PAD, false, Image.FORMAT_RGBA8)
	# Dunkles Schachbrett als Grund (Transparenz sichtbar machen).
	for y in sheet.get_height():
		for x in sheet.get_width():
			var check := ((x / 16) + (y / 16)) % 2 == 0
			sheet.set_pixel(x, y, Color(0.09, 0.09, 0.11) if check else Color(0.13, 0.13, 0.16))

	for i in imgs.size():
		var img := imgs[i]
		var scaled: Image = img.duplicate()
		scaled.resize(img.get_width() * SCALE, img.get_height() * SCALE, Image.INTERPOLATE_NEAREST)
		var cx := PAD + (i % COLS) * cell_w
		var cy := PAD + (i / COLS) * cell_h
		for y in scaled.get_height():
			for x in scaled.get_width():
				var c: Color = scaled.get_pixel(x, y)
				if c.a > 0.0:
					sheet.set_pixel(cx + x, cy + y, c)

	var out := "/private/var/folders/by/kwv07z_x0ts25n9flfw1nvk80000gn/T/opencode/shots/art_sheet.png"
	DirAccess.make_dir_recursive_absolute(out.get_base_dir())
	sheet.save_png(out)
	print("Kontaktbogen: ", out, " (", sheet.get_width(), "x", sheet.get_height(), ")")
	print("Reihenfolge (", COLS, " Spalten): ", ", ".join(PackedStringArray(FILES)))
	quit()
