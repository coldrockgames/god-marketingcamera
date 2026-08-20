## Camera node to take marketing screenshots. Allows free camera movement in the 2D scene.
##
## Allows you to explore the scene from arbitrary angles and perspectives 
## that are outside standard gameplay mechanics.[br][br]
## [color=orange]How to use[/color][br]
## Just add the MarketingCamera2D to the scene at any position in the tree.[br]
## When you activate the Camera, the scene freezes, all animations stand still to give you time to take the
## perfect screenshot.[br][br]
## [color=orange]Setup[/color][br]
## You can configure all movement values through the inspector.[br][br]
## [color=orange]Hotkeys[/color][br]
## If you do not set custom hotkeys, these are the defaults,
## which mirror 1:1 the Godot Editors behavior:[br][br]
## [param TAB]: Activate/Deactivate the MarketingCamera.[br]
## [param WASD]: Move the camera freely over the scene.[br]
## [param R]: Reset the camera to default position, zoom and rotation.[br]
## [param Mouse Wheel]: Zoom in/out.[br]
## [param Middle Mouse Button]: Rotate the camera. Hold [param SHIFT] to pan instead of rotating.[br][br]
## [color=orange]Slow-Mo and scene freeze[/color][br]
## Hold down [param CTRL] to set the scene in slow-mo mode, reducing the animation speed by 90% (default).
@tool
class_name MarketingCamera2D
extends Camera2D

## Is this the active camera rendering the scene?
@export var active:bool = false:
	set(value):
		active = value
		if not is_editor_context:
			_update_camera_state()
## If [code]true[/code], the camera will hide all CanvasLayer nodes in the scene while active.
@export var hide_ui_when_active:bool = true
## If [code]true[/code], the camera will automatically turn silent in exported games.
@export var disable_in_exports:bool = true
## The MarketingCamera will start at the exact position of this camera.
@export var base_camera:Camera2D:
	set(value):
		base_camera = value
		update_configuration_warnings()
## "Input Map" name for the activation hotkey.[br]
## If empty, the [code]TAB[/code] key will toggle activation state.
@export var activate_action:StringName = &""
## "Input Map" name for the slow-mo hotkey.[br]
## If empty, the [code]CTRL[/code] key will toggle slow-mo.
@export var slow_mo_action:StringName = &""
## The time scale during slow-mo.
@export var slow_mo_scale:float = 0.1
## The [param WASD] move speed of the camera in pixels per second.
@export_custom(PROPERTY_HINT_NONE, "suffix:px/s") var move_speed:float = 500.0
## The rotation speed when using the middle mouse button.
@export_custom(PROPERTY_HINT_NONE, "suffix:°/px") var rotation_sensitivity:float = 0.2
## The movement speed while panning the camera using [param SHIFT] and drag with the middle button held.
@export_custom(PROPERTY_HINT_NONE, "suffix:px/px") var pan_sensitivity:float = 1.0
## The zoom change multiplier when using the mouse wheel.
@export_range(0.01, 1.0, 0.01, "or_greater", "suffix:step") var zoom_speed:float = 0.1
## The minimum zoom level (zoomed out).
@export_range(0.01, 10.0, 0.01, "or_greater", "suffix:x") var min_zoom:float = 0.1
## The maximum zoom level (zoomed in).
@export_range(0.1, 100.0, 0.1, "or_greater", "suffix:x") var max_zoom:float = 10.0
## How fast the camera interpolates rotation, zoom and panning inputs.
@export_range(1.0, 30.0, 0.1, "suffix:1/s") var smoothing_speed:float = 7.5


var is_editor_context:bool = Engine.is_editor_hint() or DisplayServer.get_name() == "headless"
var is_export:bool = not OS.has_feature("editor")


var _initial_zoom:Vector2
var _runtime_min_zoom:Vector2
var _runtime_max_zoom:Vector2
var _initial_position:Vector2
var _initial_rotation:float

var _target_position:Vector2
var _target_rotation:float
var _target_zoom:Vector2
var _current_velocity:Vector2 = Vector2.ZERO


func _ready() -> void:
	update_configuration_warnings()
	if is_editor_context or (disable_in_exports and is_export):
		process_mode = Node.PROCESS_MODE_DISABLED
		set_process_unhandled_input(false)
		set_process(false)
		if is_export and base_camera:
			base_camera.make_current()
		return
	process_mode = Node.PROCESS_MODE_ALWAYS
	if base_camera:
		_initial_position = base_camera.global_position
		_initial_rotation = base_camera.global_rotation
		_initial_zoom = base_camera.zoom
	else:
		_initial_position = global_position
		_initial_rotation = global_rotation
		_initial_zoom = zoom
	global_position = _initial_position
	global_rotation = _initial_rotation
	zoom = _initial_zoom
	var base_min:float = minf(_initial_zoom.x, min_zoom)
	var base_max:float = maxf(_initial_zoom.x, max_zoom)
	_runtime_min_zoom = Vector2(base_min, base_min)
	_runtime_max_zoom = Vector2(base_max, base_max)
	_target_position = _initial_position
	_target_rotation = _initial_rotation
	_target_zoom = _initial_zoom
	ignore_rotation = false
	_update_camera_state()


func _get_configuration_warnings() -> PackedStringArray:
	var warnings:PackedStringArray = []
	if not base_camera:
		warnings.append("Base Camera is not set! MarketingCamera2D needs a starting reference.")
	return warnings


func _update_camera_state() -> void:
	if not is_inside_tree():
		return
	if active:
		make_current()
		get_tree().paused = true
		_toggle_canvas_layers(false)
	else:
		if base_camera:
			base_camera.make_current()
		get_tree().paused = false
		Engine.time_scale = 1.0
		_toggle_canvas_layers(true)



func _toggle_canvas_layers(show_ui:bool) -> void:
	if not hide_ui_when_active:
		return
	var root_node:Node = get_tree().current_scene
	if root_node:
		var canvas_layers:Array[Node] = root_node.find_children("*", "CanvasLayer", true, false)
		for layer:Node in canvas_layers:
			var canvas_layer:CanvasLayer = layer as CanvasLayer
			if canvas_layer:
				canvas_layer.visible = show_ui


func _unhandled_input(event:InputEvent) -> void:
	if is_editor_context:
		return
	var toggled:bool = false
	if activate_action != &"" and event.is_action_pressed(activate_action):
		toggled = true
	elif activate_action == &"" and event is InputEventKey:
		if event.keycode == KEY_TAB and event.pressed and not event.echo:
			toggled = true
	if toggled:
		active = !active
		if active:
			Engine.time_scale = 1.0
		return
	if not active:
		var is_slow_pressed:bool = false
		var is_slow_released:bool = false
		if slow_mo_action != &"":
			is_slow_pressed = event.is_action_pressed(slow_mo_action)
			is_slow_released = event.is_action_released(slow_mo_action)
		elif event is InputEventKey and event.keycode == KEY_CTRL and not event.echo:
			is_slow_pressed = event.pressed
			is_slow_released = not event.pressed
		if is_slow_pressed:
			Engine.time_scale = slow_mo_scale
		elif is_slow_released:
			Engine.time_scale = 1.0
		return
	if event is InputEventKey and event.keycode == KEY_R and event.pressed:
		_target_position = _initial_position
		_target_rotation = _initial_rotation
		_target_zoom = _initial_zoom
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			var dir:float = 1.0 if event.button_index == MOUSE_BUTTON_WHEEL_UP else -1.0
			var zoom_step:Vector2 = _target_zoom * (dir * zoom_speed)
			_target_zoom = (_target_zoom + zoom_step).clamp(_runtime_min_zoom, _runtime_max_zoom)
	if event is InputEventMouseMotion:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE):
			if Input.is_key_pressed(KEY_SHIFT):
				var pan_offset:Vector2 = (event.relative * pan_sensitivity) / zoom
				_target_position -= pan_offset.rotated(global_rotation)
			else:
				var look_rad:float = deg_to_rad(rotation_sensitivity)
				_target_rotation -= event.relative.x * look_rad


func _process(delta:float) -> void:
	if not active:
		return
	global_rotation = lerp_angle(global_rotation, _target_rotation, delta * smoothing_speed)
	zoom = zoom.lerp(_target_zoom, delta * smoothing_speed)
	var target_dir:Vector2 = Vector2.ZERO
	if Input.is_key_pressed(KEY_W): target_dir.y -= 1.0
	if Input.is_key_pressed(KEY_S): target_dir.y += 1.0
	if Input.is_key_pressed(KEY_A): target_dir.x -= 1.0
	if Input.is_key_pressed(KEY_D): target_dir.x += 1.0
	if target_dir.length_squared() > 0:
		target_dir = target_dir.normalized().rotated(global_rotation) * (move_speed / zoom.x)
	_current_velocity = _current_velocity.lerp(target_dir, delta * smoothing_speed)
	_target_position += _current_velocity * delta
	global_position = global_position.lerp(_target_position, delta * smoothing_speed)
