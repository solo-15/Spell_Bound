extends CharacterBody3D
## First-person controller: WASD move, Shift run, C crouch, Space jump, mouse look.
## Godot 4.x

@export_group("Speed")
@export var walk_speed: float = 5.0
@export var run_speed: float = 8.5
@export var crouch_speed: float = 2.5
@export var acceleration: float = 10.0
@export var air_control: float = 2.0
@export var jump_velocity: float = 4.5

@export_group("Camera")
@export var mouse_sensitivity: float = 0.002

@export_group("Crouch")
@export var standing_height: float = 1.8
@export var crouch_height: float = 1.0
@export var standing_eye_height: float = 1.6
@export var crouch_eye_height: float = 0.9
@export var crouch_transition_speed: float = 10.0
@export var hold_to_crouch: bool = true  # false = press C to toggle

@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var ceiling_check: RayCast3D = $CeilingCheck

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var is_crouching: bool = false
var is_running: bool = false
var _capsule: CapsuleShape3D


func _ready() -> void:
	_register_inputs()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	# Make the shape unique so changing its height doesn't affect other instances
	_capsule = (collision_shape.shape as CapsuleShape3D).duplicate()
	collision_shape.shape = _capsule
	_capsule.height = standing_height
	collision_shape.position.y = standing_height * 0.5
	head.position.y = standing_eye_height

	# Ray that detects a low ceiling above the player while crouching
	ceiling_check.position = Vector3(0, crouch_height, 0)
	ceiling_check.target_position = Vector3(0, standing_height - crouch_height + 0.05, 0)
	ceiling_check.add_exception(self)


func _unhandled_input(event: InputEvent) -> void:
	# Mouse look
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		head.rotate_x(-event.relative.y * mouse_sensitivity)
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-89), deg_to_rad(89))

	# Release / recapture mouse
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseButton and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	# Toggle crouch mode
	if not hold_to_crouch and event.is_action_pressed("crouch"):
		if is_crouching:
			if _can_stand():
				is_crouching = false
		else:
			is_crouching = true


func _physics_process(delta: float) -> void:
	_handle_crouch(delta)

	# Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Jump (can't jump while crouching)
	if Input.is_action_just_pressed("jump") and is_on_floor() and not is_crouching:
		velocity.y = jump_velocity

	# Movement input
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	# Speed selection
	is_running = (
		Input.is_action_pressed("run")
		and not is_crouching
		and input_dir.y < 0.0  # only run when moving forward
	)
	var target_speed := walk_speed
	if is_crouching:
		target_speed = crouch_speed
	elif is_running:
		target_speed = run_speed

	# Smooth acceleration
	var accel := acceleration if is_on_floor() else air_control
	var target_velocity := direction * target_speed
	velocity.x = move_toward(velocity.x, target_velocity.x, accel * target_speed * delta)
	velocity.z = move_toward(velocity.z, target_velocity.z, accel * target_speed * delta)

	move_and_slide()


func _handle_crouch(delta: float) -> void:
	if hold_to_crouch:
		if Input.is_action_pressed("crouch"):
			is_crouching = true
		elif is_crouching and _can_stand():
			is_crouching = false  # stays crouched if something is above

	var target_height := crouch_height if is_crouching else standing_height
	var target_eye := crouch_eye_height if is_crouching else standing_eye_height

	_capsule.height = lerp(_capsule.height, target_height, crouch_transition_speed * delta)
	collision_shape.position.y = _capsule.height * 0.5
	head.position.y = lerp(head.position.y, target_eye, crouch_transition_speed * delta)


func _can_stand() -> bool:
	ceiling_check.force_raycast_update()
	return not ceiling_check.is_colliding()


## Registers input actions in code so it works without touching the Input Map.
## You can delete this and set the actions in Project Settings instead.
func _register_inputs() -> void:
	_add_key("move_forward", KEY_W)
	_add_key("move_back", KEY_S)
	_add_key("move_left", KEY_A)
	_add_key("move_right", KEY_D)
	_add_key("run", KEY_SHIFT)
	_add_key("crouch", KEY_C)
	_add_key("jump", KEY_SPACE)
	_add_key("flashlight", KEY_F)


func _add_key(action: StringName, keycode: Key) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
		var ev := InputEventKey.new()
		ev.physical_keycode = keycode
		InputMap.action_add_event(action, ev)
