class_name JoystickOverlay
extends CanvasLayer
## Dynamische virtuelle Joysticks – TWIN-STICK (UI/UX §2 + M2c-Feedback):
##   linke Bildschirmhälfte  = Bewegung
##   rechte Bildschirmhälfte = Blickrichtung (Aim)
## Beide erscheinen am jeweiligen Touch-Punkt; zwei Finger bedienen beide
## Kanäle parallel (laufen + zielen). Die obere 35% des Bildschirms bleibt
## HUD vorbehalten. Bei Pause stumm – Klicks auf Level-Up-Karten dürfen
## keinen Stick auslösen.

const _BG_RADIUS := 70.0
const _KNOB_RADIUS := 26.0
const _MAX_DIST := _BG_RADIUS - 10.0
## Platzhalter-ID für die Maus-Fallback-Kanäle (emulierter Touch hat eigene
## Indizes, deshalb braucht die Maus einen eigenen Wert).
const _MOUSE_ID := -2

var _move_id := -1
var _aim_id := -1
var _move_center := Vector2.ZERO
var _aim_center := Vector2.ZERO

@onready var _bg_move: Panel = $Background
@onready var _knob_move: Panel = $Background/Knob
@onready var _bg_aim: Panel = $BackgroundAim
@onready var _knob_aim: Panel = $BackgroundAim/Knob


func _ready() -> void:
	VirtualJoystickInput.reset()
	_bg_move.visible = false
	_bg_aim.visible = false


func _input(event: InputEvent) -> void:
	if get_tree().paused:
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			_press(event.index, event.position)
		else:
			_release(event.index)
	elif event is InputEventScreenDrag:
		_drag(event.index, event.position)
	elif event is InputEventMouseButton:
		# Maus-Fallback (Desktop): nur, wenn kein Touch einen Kanal hält –
		# ein emulierter Touch+Maus-Paar am selben Punkt darf nicht doppelt greifen.
		if event.pressed:
			if _move_id == -1 and _aim_id == -1:
				_press(_MOUSE_ID, event.position)
		else:
			_release(_MOUSE_ID)
	elif event is InputEventMouseMotion:
		_drag(_MOUSE_ID, event.position)


## Kanal nach Bildschirmhälfte wählen: links Bewegen, rechts Zielen.
func _press(id: int, pos: Vector2) -> void:
	var view := get_viewport().get_visible_rect().size
	if pos.y <= view.y * 0.35:
		return  # HUD-Zone oben bleibt frei.
	if pos.x < view.x * 0.5:
		if _move_id != -1:
			return
		_move_id = id
		_move_center = pos
		_place(_bg_move, pos)
	else:
		if _aim_id != -1:
			return
		_aim_id = id
		_aim_center = pos
		_place(_bg_aim, pos)


func _release(id: int) -> void:
	if id == _move_id:
		_move_id = -1
		_bg_move.visible = false
		VirtualJoystickInput.active = false
		VirtualJoystickInput.direction = Vector2.ZERO
	if id == _aim_id:
		_aim_id = -1
		_bg_aim.visible = false
		VirtualJoystickInput.aim_active = false
		VirtualJoystickInput.aim_direction = Vector2.ZERO


func _drag(id: int, pos: Vector2) -> void:
	if id == _move_id:
		_update_knob(_knob_move, _move_center, pos, false)
	elif id == _aim_id:
		_update_knob(_knob_aim, _aim_center, pos, true)


func _place(bg: Panel, center: Vector2) -> void:
	bg.position = center - Vector2(_BG_RADIUS, _BG_RADIUS)
	bg.visible = true


func _update_knob(knob: Panel, center: Vector2, pos: Vector2, is_aim: bool) -> void:
	var offset := pos - center
	if offset.length() > _MAX_DIST:
		offset = offset.normalized() * _MAX_DIST
	knob.position = Vector2(_BG_RADIUS, _BG_RADIUS) + offset \
		- Vector2(_KNOB_RADIUS, _KNOB_RADIUS)
	var out := offset / _MAX_DIST
	if is_aim:
		VirtualJoystickInput.aim_active = true
		VirtualJoystickInput.aim_direction = out
	else:
		VirtualJoystickInput.active = true
		VirtualJoystickInput.direction = out
