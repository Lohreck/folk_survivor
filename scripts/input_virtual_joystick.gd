class_name VirtualJoystickInput
## Statischer Zugriff auf die Joystick-Ausgaben (vom Player gelesen).
## Twin-Stick (M2c-Feedback): Kanal "direction" = Bewegung (linke
## Bildschirmhälfte), Kanal "aim_direction" = Blickrichtung (rechte
## Bildschirmhälfte bzw. zweiter Gamepad-Stick über die aim_*-Aktionen).

static var active := false
static var direction := Vector2.ZERO
## Aim-Kanal des Touch-Sticks.
static var aim_active := false
static var aim_direction := Vector2.ZERO


static func get_output() -> Vector2:
	return direction if active else Vector2.ZERO


static func get_aim() -> Vector2:
	return aim_direction if aim_active else Vector2.ZERO


## Alles zurücksetzen (Run-Neustart, Tests).
static func reset() -> void:
	active = false
	direction = Vector2.ZERO
	aim_active = false
	aim_direction = Vector2.ZERO
