class_name JoystickOverlay
extends CanvasLayer
## Dynamischer virtueller Joystick (UI/UX §2: erscheint am Touch-Punkt).
##
## Wird als CanvasLayer über dem Spiel gerendert, damit er bei Kamera-Bewegung
## stabil bleibt. Die Ausgabe liegt im statischen Zugriff VirtualJoystickInput.

const _BG_RADIUS := 70.0
const _KNOB_RADIUS := 26.0
const _MAX_DIST := _BG_RADIUS - 10.0

var _touch_id := -1
var _center := Vector2.ZERO
var _knob_pos := Vector2.ZERO
var _dragging := false

@onready var _bg: Panel = $Background
@onready var _knob: Panel = $Background/Knob


func _ready() -> void:
	VirtualJoystickInput.active = false
	_bg.visible = false


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and _touch_id == -1:
			if event.position.y > get_viewport().get_visible_rect().size.y * 0.35:
				_touch_id = event.index
				_center = event.position
				_bg.position = _center - Vector2(_BG_RADIUS, _BG_RADIUS)
				_bg.visible = true
				_dragging = true
				_update_knob(event.position)
		elif not event.pressed and event.index == _touch_id:
			_release()
	elif event is InputEventScreenDrag and event.index == _touch_id:
		_update_knob(event.position)
	elif event is InputEventMouseButton:
		if event.pressed and _touch_id == -1 and event.position.y > get_viewport().get_visible_rect().size.y * 0.35:
			_touch_id = -2
			_center = event.position
			_bg.position = _center - Vector2(_BG_RADIUS, _BG_RADIUS)
			_bg.visible = true
			_dragging = true
			_update_knob(event.position)
		elif not event.pressed and _touch_id == -2:
			_release()
	elif event is InputEventMouseMotion and _touch_id == -2 and _dragging:
		_update_knob(event.position)


func _update_knob(pos: Vector2) -> void:
	var offset := pos - _center
	if offset.length() > _MAX_DIST:
		offset = offset.normalized() * _MAX_DIST
	_knob_pos = offset
	_knob.position = Vector2(_BG_RADIUS, _BG_RADIUS) + _knob_pos - Vector2(_KNOB_RADIUS, _KNOB_RADIUS)
	VirtualJoystickInput.active = true
	VirtualJoystickInput.direction = offset / _MAX_DIST


func _release() -> void:
	_touch_id = -1
	_dragging = false
	_bg.visible = false
	VirtualJoystickInput.active = false
	VirtualJoystickInput.direction = Vector2.ZERO
