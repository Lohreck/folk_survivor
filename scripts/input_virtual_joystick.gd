class_name VirtualJoystickInput
## Statischer Zugriff auf die Joystick-Ausgabe (vom Player gelesen).

static var active := false
static var direction := Vector2.ZERO


static func get_output() -> Vector2:
	return direction if active else Vector2.ZERO
