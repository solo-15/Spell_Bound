extends Node
## AUTOLOAD this as "GameState"  (Project > Project Settings > Globals > Autoload)
## Holds collected letters, puzzle flags, the PC password/code, and a simple
## "inspect" popup used by papers / drawers / notebook.

signal letter_found(slot: int, letter: String)
signal all_letters_found(word: String)
signal flag_changed(flag: StringName)

const LETTER_SLOTS := 4

# ---- PUZZLE DATA: change these to whatever you want -----------------------
var pc_password: String = "DM2029"   # written in the notebook, used on PC login
var archive_code: String = "4827"      # 4-digit code for Locked_Archive
# -----------------------------------------------------------------------------

var letters: Dictionary = {}   # slot (1..4) -> letter
var flags: Dictionary = {}

var _ui_depth := 0
var ui_open: bool:
	get:
		return _ui_depth > 0

var _root: Control
var _title: Label
var _body: Label
var _letter_label: Label
var _ok: Button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_overlay()


# ---------------------------------------------------------------- letters ----
func collect_letter(slot: int, letter: String) -> void:
	if slot <= 0 or letter == "" or letters.has(slot):
		return
	letters[slot] = letter
	letter_found.emit(slot, letter)
	if letters.size() >= LETTER_SLOTS:
		all_letters_found.emit(get_word())


func has_letter(slot: int) -> bool:
	return letters.has(slot)


func get_word() -> String:
	var w := ""
	for i in range(1, LETTER_SLOTS + 1):
		w += str(letters.get(i, "_"))
	return w


# ------------------------------------------------------------------ flags ----
func set_flag(flag: StringName) -> void:
	if not flags.has(flag):
		flags[flag] = true
		flag_changed.emit(flag)


func has_flag(flag: StringName) -> bool:
	return flags.has(flag)


# --------------------------------------------------------------- UI lock -----
## Call when any UI opens. Frees the mouse and freezes the player.
func open_ui() -> void:
	_ui_depth += 1
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func close_ui() -> void:
	_ui_depth = max(0, _ui_depth - 1)
	if _ui_depth == 0:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


# ------------------------------------------------------- message overlay -----
## Shows an inspect popup. Use {password} and {code} in text to insert puzzle data.
func show_message(title: String, body: String, letter_slot: int = 0, letter: String = "") -> void:
	_ensure_overlay()
	_title.text = title
	_body.text = body.replace("{password}", pc_password).replace("{code}", archive_code)
	_letter_label.visible = letter != ""
	_letter_label.text = letter
	_root.visible = true
	open_ui()
	_ok.grab_focus()
	if letter != "":
		collect_letter(letter_slot, letter)


func _close_message() -> void:
	if _root and _root.visible:
		_root.visible = false
		close_ui()


func _unhandled_input(event: InputEvent) -> void:
	if _root and _root.visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_close_message()


func _ensure_overlay() -> void:
	if _root == null:
		_build_overlay()


func _build_overlay() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 50
	add_child(layer)

	_root = Control.new()
	_root.visible = false
	layer.add_child(_root)
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	_root.add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var center := CenterContainer.new()
	_root.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(560, 0)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.11, 0.14, 0.28)
	sb.border_color = Color(0.3, 0.36, 0.6)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(16)
	sb.set_content_margin_all(28)
	panel.add_theme_stylebox_override("panel", sb)
	center.add_child(panel)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 14)
	panel.add_child(vb)

	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 28)
	vb.add_child(_title)

	_body = Label.new()
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.custom_minimum_size = Vector2(500, 0)
	_body.add_theme_font_size_override("font_size", 20)
	vb.add_child(_body)

	_letter_label = Label.new()
	_letter_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_letter_label.add_theme_font_size_override("font_size", 120)
	_letter_label.add_theme_color_override("font_color", Color(1.0, 0.82, 0.3))
	vb.add_child(_letter_label)

	_ok = Button.new()
	_ok.text = "Ok"
	_ok.custom_minimum_size = Vector2(120, 40)
	_ok.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_ok.pressed.connect(_close_message)
	vb.add_child(_ok)
