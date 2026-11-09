extends SpotLight3D
## Flashlight with battery. Press F to toggle.
## Attach to a SpotLight3D that is a child of the player's Camera3D.
## Godot 4.x

signal toggled(is_on: bool)
signal battery_changed(current: float, maximum: float)

@export_group("Light")
@export var light_energy_on: float = 4.0
@export var light_range: float = 25.0
@export var light_angle: float = 30.0


@export_group("Battery")
@export var use_battery: bool = true
@export var max_battery: float = 100.0
@export var drain_per_second: float = 2.0       # while on
@export var recharge_per_second: float = 0.0    # while off (0 = no passive recharge)
@export var min_battery_to_turn_on: float = 1.0

@export_group("Flicker")
@export var flicker_threshold: float = 20.0     # battery % where flicker begins
@export var flicker_strength: float = 0.7       # 0 = none, 1 = heavy

@export_group("Audio (optional)")
@export var click_on_sound: AudioStream
@export var click_off_sound: AudioStream

var battery: float
var is_on: bool = false

var _audio: AudioStreamPlayer
var _flicker_timer: float = 0.0
var _flicker_mult: float = 1.0


func _ready() -> void:
	battery = max_battery
	spot_range = light_range
	spot_angle = light_angle
	light_color = light_color  # keeps export value applied to Light3D.light_color
	shadow_enabled = true
	visible = false
	light_energy = 0.0

	_audio = AudioStreamPlayer.new()
	add_child(_audio)

	battery_changed.emit(battery, max_battery)


func _unhandled_input(event: InputEvent) -> void:
	if GameState.ui_open:
		return
	if event.is_action_pressed("flashlight"):
		toggle()


func _process(delta: float) -> void:
	if is_on:
		if use_battery:
			battery = max(battery - drain_per_second * delta, 0.0)
			battery_changed.emit(battery, max_battery)
			if battery <= 0.0:
				turn_off()
				return
		_update_flicker(delta)
		light_energy = light_energy_on * _flicker_mult * _battery_dim()
	elif use_battery and recharge_per_second > 0.0 and battery < max_battery:
		battery = min(battery + recharge_per_second * delta, max_battery)
		battery_changed.emit(battery, max_battery)


func toggle() -> void:
	if is_on:
		turn_off()
	else:
		turn_on()


func turn_on() -> void:
	if use_battery and battery < min_battery_to_turn_on:
		return  # dead battery
	is_on = true
	visible = true
	light_energy = light_energy_on
	_play(click_on_sound)
	toggled.emit(true)


func turn_off() -> void:
	if not is_on:
		return
	is_on = false
	visible = false
	light_energy = 0.0
	_play(click_off_sound)
	toggled.emit(false)


func add_battery(amount: float) -> void:
	battery = clamp(battery + amount, 0.0, max_battery)
	battery_changed.emit(battery, max_battery)


func get_battery_percent() -> float:
	return battery / max_battery * 100.0


# Light slowly dims in the last part of the battery.
func _battery_dim() -> float:
	if not use_battery:
		return 1.0
	return clamp(remap(get_battery_percent(), 0.0, flicker_threshold, 0.4, 1.0), 0.4, 1.0)


# Random flickering when the battery is low.
func _update_flicker(delta: float) -> void:
	if not use_battery or get_battery_percent() > flicker_threshold:
		_flicker_mult = 1.0
		return

	_flicker_timer -= delta
	if _flicker_timer <= 0.0:
		# The lower the battery, the more often and the harder it flickers
		var severity := 1.0 - get_battery_percent() / flicker_threshold
		if randf() < 0.25 + severity * 0.5:
			_flicker_mult = randf_range(1.0 - flicker_strength, 1.0 - flicker_strength * 0.2)
		else:
			_flicker_mult = 1.0
		_flicker_timer = randf_range(0.03, 0.2)


func _play(stream: AudioStream) -> void:
	if stream == null:
		return
	_audio.stream = stream
	_audio.play()
