extends RayCast3D
## Attach to a RayCast3D that is a child of the player's Camera3D.
## Looks at objects that have an interact() method and shows "[E] prompt".

@export var reach: float = 3.0

var _label: Label
var _current: Object = null


func _ready() -> void:
	_register_action()
	target_position = Vector3(0, 0, -reach)
	enabled = true
	collide_with_areas = false
	collide_with_bodies = true

	# Don't hit the player's own collider
	var n: Node = get_parent()
	while n:
		if n is CollisionObject3D:
			add_exception(n)
			break
		n = n.get_parent()

	_build_hud()


func _physics_process(_delta: float) -> void:
	_current = null
	if not GameState.ui_open and is_colliding():
		var c := get_collider()
		if c and c.has_method("interact"):
			_current = c

	_label.visible = _current != null
	if _current:
		var p: String = "Interact"
		if _current.has_method("get_prompt"):
			p = str(_current.get_prompt())
		_label.text = "[E]  " + p


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and _current and not GameState.ui_open:
		get_viewport().set_input_as_handled()
		_current.interact()


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)

	var cross := Label.new()
	cross.text = "+"
	cross.add_theme_font_size_override("font_size", 22)
	layer.add_child(cross)
	cross.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	cross.grow_horizontal = Control.GROW_DIRECTION_BOTH
	cross.grow_vertical = Control.GROW_DIRECTION_BOTH

	_label = Label.new()
	_label.add_theme_font_size_override("font_size", 24)
	_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_label.add_theme_constant_override("outline_size", 6)
	layer.add_child(_label)
	_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_label.offset_top = -120
	_label.offset_bottom = -90
	_label.visible = false


func _register_action() -> void:
	if not InputMap.has_action("interact"):
		InputMap.add_action("interact")
		var ev := InputEventKey.new()
		ev.physical_keycode = KEY_E
		InputMap.action_add_event("interact", ev)
