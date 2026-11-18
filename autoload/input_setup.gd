extends Node
## Registra las acciones de entrada por código (más fácil de revisar en diff
## que el bloque [input] de project.godot). El rebinding de la Beta partirá de aquí.

const KEYS := {
	"move_left": [KEY_A, KEY_LEFT],
	"move_right": [KEY_D, KEY_RIGHT],
	"move_up": [KEY_W, KEY_UP],
	"move_down": [KEY_S, KEY_DOWN],
	"jump": [KEY_SPACE, KEY_K],
	"attack": [KEY_J, KEY_X],
	"dodge": [KEY_L, KEY_SHIFT],
	"heal": [KEY_F, KEY_C],
	"interact": [KEY_E],
	"pause": [KEY_ESCAPE],
}

const PAD_BUTTONS := {
	"jump": [JOY_BUTTON_A],
	"attack": [JOY_BUTTON_X],
	"dodge": [JOY_BUTTON_B, JOY_BUTTON_RIGHT_SHOULDER],
	"heal": [JOY_BUTTON_Y],
	"interact": [JOY_BUTTON_DPAD_UP],
	"pause": [JOY_BUTTON_START],
}

const PAD_AXES := {
	"move_left": [JOY_AXIS_LEFT_X, -1.0],
	"move_right": [JOY_AXIS_LEFT_X, 1.0],
	"move_up": [JOY_AXIS_LEFT_Y, -1.0],
	"move_down": [JOY_AXIS_LEFT_Y, 1.0],
}


func _init() -> void:
	for action: String in KEYS:
		if not InputMap.has_action(action):
			InputMap.add_action(action, 0.3)
		for keycode: Key in KEYS[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = keycode
			InputMap.action_add_event(action, ev)
	for action: String in PAD_BUTTONS:
		for button: JoyButton in PAD_BUTTONS[action]:
			var ev := InputEventJoypadButton.new()
			ev.button_index = button
			InputMap.action_add_event(action, ev)
	for action: String in PAD_AXES:
		var ev := InputEventJoypadMotion.new()
		ev.axis = PAD_AXES[action][0]
		ev.axis_value = PAD_AXES[action][1]
		InputMap.action_add_event(action, ev)
