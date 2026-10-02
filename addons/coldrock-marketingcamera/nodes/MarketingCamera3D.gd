## Camera node to take marketing screenshots. Allows free camera movement in the scene.
##
## Allows you to explore the scene from arbitrary angles and perspectives 
## that are outside standard gameplay mechanics.[br][br]
## [color=orange]How to use[/color][br]
## Just add the MarketingCamera3D to the scene at any position in the tree.[br]
## When you activate the Camera, the scene freezes, all animations stand still to give you time to take the
## perfect screenshot.[br][br]
## [color=orange]Setup[/color][br]
## You can configure all movement values through the inspector.[br][br]
## [color=orange]Hotkeys[/color][br]
## If you do not set custom hotkeys, these are the defaults,
## which mirror 1:1 the Godot Editors behavior:[br][br]
## [param TAB]: Activate/Deactivate the MarketingCamera.[br]
## [param WASD]: Move the camera freely over the scene.[br]
## [param QE]: Move the camera up/down along the Y-axis.[br]
## [param R]: Reset the camera to default position, fov and rotation.[br]
## [param Mouse Wheel]: Zoom in/out by moving the camera closer. Hold [param SHIFT] to modify the FOV.[br]
## [param Middle Mouse Button]: Rotate the camera. Hold [param SHIFT] to pan instead of rotating.[br][br]
## [color=orange]Slow-Mo and scene freeze[/color][br]
## Hold down [param CTRL] to set the scene in slow-mo mode, reducing the animation speed by 90% (default).
@tool
class_name MarketingCamera3D
extends Camera3D

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
@export var base_camera:Camera3D:
	set(value):
		base_camera = value
		update_configuration_warnings()
## "Input Map" name for the activation hotkey.[br]
## If empty, the [code]TAB[/code] key will toggle activation state.
@export var activate_action:StringName = &""
## "Input Map" name for dumping camera data.[br]
## If empty, the [code]SPACE[/code] key will trigger the dump.
@export var dump_action:StringName = &""
## "Input Map" name for the slow-mo hotkey.[br]
## If empty, the [code]CTRL[/code] key will toggle slow-mo.
@export var slow_mo_action:StringName = &""
## The time scale during slow-mo.
@export var slow_mo_scale:float = 0.1
## The [param WASD] move speed of the camera.
@export_custom(PROPERTY_HINT_NONE, "suffix:m/s") var move_speed:float = 10.0
## The rotation speed when using the middle mouse button.
@export_custom(PROPERTY_HINT_NONE, "suffix:°/px") var look_sensitivity:float = 0.2
## The movement speed while panning the camera using [param SHIFT] and drag with the middle button held.
@export_custom(PROPERTY_HINT_NONE, "suffix:m/px") var pan_sensitivity:float = 0.01
## All [param WASD/QE]-action speeds will be multiplied with this value if you hold down the [param SHIFT]
## key while moving.
@export var shift_speed_multiplier:float = 2.0
## The FOV change speed when using SHIFT + mouse wheel.
@export_range(0.1, 10.0, 0.1, "or_greater", "suffix:°/scroll") var fov_speed:float = 2.0
## The minimum FOV value the camera has.[br]
## [color=orange]NOTE:[/color] If the [member base_camera]'s fov is less than the value you set here, 
## the [member base_camera]'s FOV wins.
@export_range(1.0, 179.0, 1.0, "suffix:°") var min_fov:float = 10.0
## The maximum FOV value the camera has.[br]
## [color=orange]NOTE:[/color] If the [member base_camera]'s fov is greater than the value you set here, 
## the [member base_camera]'s FOV wins.
@export_range(1.0, 179.0, 1.0, "suffix:°") var max_fov:float = 120.0
## How fast the camera interpolates rotation, zoom and panning inputs.
@export_range(1.0, 30.0, 0.1, "suffix:1/s") var smoothing_speed:float = 7.5


var is_editor_context = Engine.is_editor_hint() or DisplayServer.get_name() == "headless"
var is_export:bool = not OS.has_feature("editor")


var _initial_fov:float
var _runtime_min_fov:float
var _runtime_max_fov:float
var _initial_transform:Transform3D
var _target_rotation:Vector3
var _target_fov:float
var _target_pan_offset:Vector3 = Vector3.ZERO
var _current_velocity:Vector3 = Vector3.ZERO


func _ready() -> void:
	update_configuration_warnings()
	if is_editor_context or (disable_in_exports and is_export):
		process_mode = Node.PROCESS_MODE_DISABLED
		set_process_unhandled_input(false)
		set_process(false)
		if is_export and base_camera:
			base_camera.current = true
		return
	process_mode = Node.PROCESS_MODE_ALWAYS
	if base_camera:
		_initial_transform = base_camera.global_transform
		global_transform = _initial_transform
		_initial_fov = base_camera.fov
		fov = _initial_fov
	else:
		_initial_fov = fov
	_runtime_min_fov = minf(_initial_fov, min_fov)
	_runtime_max_fov = maxf(_initial_fov, max_fov)
	_target_rotation = rotation
	_target_fov = fov
	_target_pan_offset = Vector3.ZERO
	_update_camera_state()


func _get_configuration_warnings() -> PackedStringArray:
	var warnings:PackedStringArray = []
	if not base_camera:
		warnings.append("Base Camera is not set! MarketingCamera3D needs a starting reference.")
	return warnings


func _update_camera_state() -> void:
	if not is_inside_tree():
		return
	if active:
		_print_help()
		make_current()
		get_tree().paused = true
		_toggle_canvas_layers(false)
	else:
		if base_camera:
			base_camera.make_current()
		get_tree().paused = false
		Engine.time_scale = 1.0
		_toggle_canvas_layers(true)


func _print_help() -> void:
	print_rich("\n[color=cyan]Marketing Camera Keyboard Control[/color]")
	print_rich("[color=cyan]---------------------------------[/color]")
	print_rich("[color=yellow]TAB[/color]           Activate/Deactivate the MarketingCamera.")
	print_rich("[color=yellow]SPACE[/color]         Dump camera transform, rotation & FOV to log and clipboard.")
	print_rich("[color=yellow]WASD[/color]          Move the camera freely over the scene.")
	print_rich("[color=yellow]QE[/color]            Move the camera up/down along the Y-axis.")
	print_rich("              (Hold down [color=yellow]SHIFT[/color] while moving [color=yellow]WASD/QE[/color] to double up the velocity.")
	print_rich("[color=yellow]R[/color]             Reset the camera to default position, FOV and rotation.")
	print_rich("[color=yellow]WHEEL[/color]         Zoom in/out by moving the camera closer. Hold [color=yellow]SHIFT[/color] to modify the FOV instead.")
	print_rich("[color=yellow]MIDDLE BUTTON[/color] Rotate the camera. Hold [color=yellow]SHIFT[/color] to pan instead of rotating.")
	print_rich("[color=yellow]CTRL[/color]          Hold down to set the scene into slo-mo mode.")
	print_rich("              (Works always, even when the camera is not active!)")
	print_rich("[color=cyan]---------------------------------[/color]")


func _print_camera_data() -> void:
	var pos:Vector3 = global_position
	var rot:Vector3 = global_rotation_degrees
	var log_str:String = "\n[b][color=yellow]--- MARKETING CAMERA 3D TELEMETRY DUMP ---[/color][/b]\n"
	log_str += "Path: %s\n" % get_path()
	log_str += "Position: Vector3(%.3f, %.3f, %.3f)\n" % [pos.x, pos.y, pos.z]
	log_str += "Rotation (Deg): Vector3(%.3f, %.3f, %.3f)\n" % [rot.x, rot.y, rot.z]
	log_str += "FOV: %.2f°\n" % fov
	log_str += "[color=yellow]-----------------------------------------[/color]"
	print_rich(log_str)
	var snippet:String = "global_position = Vector3(%.3f, %.3f, %.3f)\n" % [pos.x, pos.y, pos.z]
	snippet += "global_rotation_degrees = Vector3(%.3f, %.3f, %.3f)\n" % [rot.x, rot.y, rot.z]
	snippet += "fov = %.2f" % fov
	DisplayServer.clipboard_set(snippet)
	print_rich("[color=green]Transform snippet copied to clipboard![/color]")


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
		global_transform = _initial_transform
		fov = _initial_fov
		_target_rotation = rotation
		_target_fov = fov
		_target_pan_offset = Vector3.ZERO
	var is_dump:bool = false
	if dump_action != &"" and event.is_action_pressed(dump_action):
		is_dump = true
	elif event is InputEventKey and event.keycode == KEY_SPACE and event.pressed and not event.echo:
		is_dump = true
	if is_dump:
		_print_camera_data()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			var dir:float = 1.0 if event.button_index == MOUSE_BUTTON_WHEEL_DOWN else -1.0
			if Input.is_key_pressed(KEY_SHIFT):
				_target_fov = clampf(_target_fov + (dir * fov_speed), _runtime_min_fov, _runtime_max_fov)
			else:
				var zoom_dir:Vector3 = global_transform.basis * (Vector3.BACK * dir * move_speed * 0.1)
				_target_pan_offset += zoom_dir
	if event is InputEventMouseMotion:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE):
			if Input.is_key_pressed(KEY_SHIFT):
				var pan_forward:Vector3 = Vector3(-sin(_target_rotation.y), 0.0, -cos(_target_rotation.y))
				var pan_right:Vector3 = Vector3(cos(_target_rotation.y), 0.0, -sin(_target_rotation.y))
				var pan_offset:Vector3 = (-pan_right * event.relative.x + pan_forward * event.relative.y) * pan_sensitivity
				_target_pan_offset += pan_offset
			else:
				var look_rad:float = deg_to_rad(look_sensitivity)
				_target_rotation.y -= event.relative.x * look_rad
				_target_rotation.x -= event.relative.y * look_rad
				_target_rotation.x = clampf(_target_rotation.x, -PI / 2.0, PI / 2.0)
				_target_rotation.z = 0.0
				_target_pan_offset.y += event.relative.y * pan_sensitivity


func _process(delta:float) -> void:
	if not active:
		return
	rotation.x = lerp_angle(rotation.x, _target_rotation.x, delta * smoothing_speed)
	rotation.y = lerp_angle(rotation.y, _target_rotation.y, delta * smoothing_speed)
	fov = lerpf(fov, _target_fov, delta * smoothing_speed)
	var pan_step:Vector3 = _target_pan_offset * clampf(delta * smoothing_speed, 0.0, 1.0)
	global_position += pan_step
	_target_pan_offset -= pan_step
	var forward:Vector3 = Vector3(-sin(rotation.y), 0.0, -cos(rotation.y))
	var right:Vector3 = Vector3(cos(rotation.y), 0.0, -sin(rotation.y))
	var target_dir:Vector3 = Vector3.ZERO
	var multiplier:float = shift_speed_multiplier if Input.is_key_pressed(KEY_SHIFT) else 1.0
	if Input.is_key_pressed(KEY_W): target_dir += forward
	if Input.is_key_pressed(KEY_S): target_dir -= forward
	if Input.is_key_pressed(KEY_A): target_dir -= right
	if Input.is_key_pressed(KEY_D): target_dir += right
	if Input.is_key_pressed(KEY_E): target_dir += Vector3.UP
	if Input.is_key_pressed(KEY_Q): target_dir -= Vector3.UP
	if target_dir.length_squared() > 0:
		target_dir = target_dir.normalized() * move_speed * multiplier
	_current_velocity = _current_velocity.lerp(target_dir, delta * smoothing_speed)
	global_position += _current_velocity * delta
