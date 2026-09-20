extends ColorRect
class_name DeathScreen
## Game-Over-Overlay.
##
## Wichtig: Läuft mit PROCESS_MODE_ALWAYS, weil der Spielbaum bei Spielertod
## pausiert wird. Ein pausierender/killender Hauptknoten bekommt sonst keine
## Eingaben mehr – der Neustart wäre unmöglich.

signal restart_requested

var _stats_label: Label
var _title_label: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_stats_label = get_node("VBox/Stats")
	_title_label = get_node("VBox/Title")
	hide()


func show_results(run_time: String, kills: int, level: int) -> void:
	_title_label.text = "Gefallen!"
	color = Color(0.15, 0, 0, 0.82)
	_show_stats(run_time, kills, level)


## Sieg-Variante (M2c-3): Leshy besiegt -> grüner Screen, anderer Titel.
func show_victory(run_time: String, kills: int, level: int) -> void:
	_title_label.text = "Leshy ist gefallen!"
	color = Color(0.02, 0.2, 0.06, 0.85)
	_show_stats(run_time, kills, level)


func _show_stats(run_time: String, kills: int, level: int) -> void:
	_stats_label.text = "Zeit: %s   Kills: %d   Level: %d" % [run_time, kills, level]
	show()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_R:
		restart_requested.emit()
	elif event is InputEventScreenTouch and event.pressed:
		restart_requested.emit()
	elif event is InputEventMouseButton and event.pressed:
		restart_requested.emit()