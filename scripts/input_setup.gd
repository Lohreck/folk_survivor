extends Node
## Twin-Stick-Input-Aktionen (M2c-Feedback). Registriert zur Laufzeit als
## Autoload – Code statt project.godot-[input], weil die Textserialisierung
## von InputEvent-Objekten handgeschrieben fehleranfällig ist. Idempotent:
## existierende Aktionen bleiben unangetastet (Neustart/Testsicher).
##
##   Links  (Bewegung):    WASD + Pfeiltasten + D-Pad + linker Gamepad-Stick
##   Rechts (Blickrichtung): rechter Gamepad-Stick
## Touch: zweiter dynamischer Stick in der rechten Bildschirmhälfte
## (JoystickOverlay) speist denselben Ziel-Kanal.

const DEADZONE_MOVE := 0.35
const DEADZONE_AIM := 0.4


func _ready() -> void:
	_register_move(&"move_left", [KEY_A, KEY_LEFT], JOY_BUTTON_DPAD_LEFT, JOY_AXIS_LEFT_X, -1.0)
	_register_move(&"move_right", [KEY_D, KEY_RIGHT], JOY_BUTTON_DPAD_RIGHT, JOY_AXIS_LEFT_X, 1.0)
	_register_move(&"move_up", [KEY_W, KEY_UP], JOY_BUTTON_DPAD_UP, JOY_AXIS_LEFT_Y, -1.0)
	_register_move(&"move_down", [KEY_S, KEY_DOWN], JOY_BUTTON_DPAD_DOWN, JOY_AXIS_LEFT_Y, 1.0)
	_register_aim(&"aim_left", JOY_AXIS_RIGHT_X, -1.0)
	_register_aim(&"aim_right", JOY_AXIS_RIGHT_X, 1.0)
	_register_aim(&"aim_up", JOY_AXIS_RIGHT_Y, -1.0)
	_register_aim(&"aim_down", JOY_AXIS_RIGHT_Y, 1.0)
	# ui_accept fuer den Controller: Die Godot-Defaults binden hier nur Tasten
	# (Enter/Space) – ohne A-Knopf wuerde die fokussierte Karte mit dem
	# Gamepad nie ausloesen (M2c-Feedback: Perk-Auswahl per Controller tot).
	_register_ui_accept()


func _register_ui_accept() -> void:
	var action: StringName = &"ui_accept"
	if not InputMap.has_action(action):
		return
	var a := InputEventJoypadButton.new()
	a.button_index = JOY_BUTTON_A
	if not InputMap.action_has_event(action, a):
		InputMap.action_add_event(action, a)


func _register_move(action: StringName, keys: Array, dpad: JoyButton,
		axis: JoyAxis, axis_value: float) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action, DEADZONE_MOVE)
	for key in keys:
		var key_ev := InputEventKey.new()
		key_ev.keycode = key
		InputMap.action_add_event(action, key_ev)
	var dpad_ev := InputEventJoypadButton.new()
	dpad_ev.button_index = dpad
	InputMap.action_add_event(action, dpad_ev)
	InputMap.action_add_event(action, _axis_event(axis, axis_value))


func _register_aim(action: StringName, axis: JoyAxis, axis_value: float) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action, DEADZONE_AIM)
	InputMap.action_add_event(action, _axis_event(axis, axis_value))


func _axis_event(axis: JoyAxis, axis_value: float) -> InputEventJoypadMotion:
	var ev := InputEventJoypadMotion.new()
	ev.axis = axis
	ev.axis_value = axis_value
	return ev
