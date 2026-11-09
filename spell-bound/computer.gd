extends StaticBody3D
class_name Computer
## Interactive PC that follows the template screens:
##   Login (password) -> Desktop -> Folder #1 welcome -> Locked_Archive (4-digit code)
##   -> Letter window.
## Needs a CollisionShape3D child. The whole UI is built in code, so there is
## nothing else to set up. Optional textures let you use your template art.
## Password and archive code come from GameState (same values the notebook shows).

@export var prompt: String = "Use computer"
@export var workstation_name: String = "COMLAB Workstation #04"
@export_multiline var folder_message: String = "Welcome to Station 04. You have successfully accessed the system terminal! One final encrypted file remains on the desktop."
@export var password_case_sensitive: bool = false

@export_group("Letter reward")
@export_range(1, 4) var letter_slot: int = 4
@export var letter: String = "R"

@export_group("Optional art from your template")
@export var login_background: Texture2D
@export var desktop_background: Texture2D
@export var user_icon: Texture2D
@export var recycle_icon: Texture2D
@export var folder_icon: Texture2D          # blue folder
@export var locked_folder_icon: Texture2D   # yellow folder
@export var ui_font: Font                   # e.g. a pixel font

const DARK_TEXT := Color(0.05, 0.05, 0.12)
const ERROR_RED := Color(1.0, 0.25, 0.3)

var _layer: CanvasLayer
var _root: Control
var _login: Control
var _desktop: Control
var _popup: Control
var _pw_edit: LineEdit
var _pw_error: Label
var _code_edit: LineEdit
var _code_error: Label

var _is_open := false
var _logged_in := false
var _archive_unlocked := false


func get_prompt() -> String:
	return prompt


func interact() -> void:
	if _layer == null:
		_build_ui()
	_layer.visible = true
	if not _is_open:
		_is_open = true
		GameState.open_ui()
	_close_popup()
	_login.visible = not _logged_in
	_desktop.visible = _logged_in
	if not _logged_in:
		_pw_error.text = ""
		_pw_edit.text = ""
		_pw_edit.grab_focus()


func _close_computer() -> void:
	_close_popup()
	_layer.visible = false
	if _is_open:
		_is_open = false
		GameState.close_ui()


func _input(event: InputEvent) -> void:
	if _layer == null or not _layer.visible:
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if _popup:
			_close_popup()
		else:
			_close_computer()


# ------------------------------------------------------------ login ----------
func _try_login(_text: String = "") -> void:
	var entered := _pw_edit.text.strip_edges()
	var target: String = GameState.pc_password
	var ok := entered == target
	if not password_case_sensitive:
		ok = entered.to_lower() == target.to_lower()

	if ok:
		_logged_in = true
		_pw_error.text = ""
		_login.visible = false
		_desktop.visible = true
	else:
		_pw_error.text = "Access Denied: Invalid Password"
		_pw_edit.text = ""
		_pw_edit.grab_focus()


# ----------------------------------------------------------- desktop ---------
func _on_recycle() -> void:
	var body := _open_window("Recycle Bin")
	body.add_child(_label("The Recycle Bin is empty.", 22, DARK_TEXT))
	body.add_child(_ok_button(_close_popup))


func _on_folder() -> void:
	var body := _open_window("Folder #1")
	body.add_child(_label("Folder #1", 44, DARK_TEXT))
	body.add_child(_label(folder_message, 20, DARK_TEXT, HORIZONTAL_ALIGNMENT_CENTER, true))
	body.add_child(_ok_button(_close_popup))


func _on_archive() -> void:
	if _archive_unlocked:
		_show_letter()
	else:
		_open_code_dialog()


func _try_code(_text: String = "") -> void:
	if _code_edit.text == GameState.archive_code:
		_archive_unlocked = true
		_show_letter()
	else:
		_code_error.text = "Incorrect Passcode"
		_code_edit.text = ""
		_code_edit.grab_focus()


func _show_letter() -> void:
	var body := _open_window("Locked_Archive")
	body.add_child(_label("Letter #%d" % letter_slot, 44, DARK_TEXT))
	body.add_child(_label(letter, 120, DARK_TEXT))
	body.add_child(_ok_button(_close_popup))
	GameState.collect_letter(letter_slot, letter)


func _filter_digits(t: String) -> void:
	var clean := ""
	for c in t:
		if c >= "0" and c <= "9":
			clean += c
	if clean != t:
		_code_edit.text = clean
		_code_edit.caret_column = clean.length()


# ---------------------------------------------------------- UI building ------
func _build_ui() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 60
	add_child(_layer)

	_root = Control.new()
	_layer.add_child(_root)
	_full(_root)

	_login = _build_login()
	_root.add_child(_login)
	_full(_login)

	_desktop = _build_desktop()
	_root.add_child(_desktop)
	_full(_desktop)

	var exit := _button("Log Off  (Esc)")
	_root.add_child(exit)
	exit.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_MINSIZE, 16)
	exit.pressed.connect(_close_computer)


func _build_login() -> Control:
	var page := Control.new()
	var bg := _background(login_background, Color(0.1, 0.17, 0.38))
	page.add_child(bg)
	_full(bg)

	var center := CenterContainer.new()
	page.add_child(center)
	_full(center)

	var glass := PanelContainer.new()
	var gs := _flat(Color(1, 1, 1, 0.12), 40)
	gs.set_content_margin_all(70)
	glass.add_theme_stylebox_override("panel", gs)
	center.add_child(glass)

	var vb := VBoxContainer.new()
	vb.custom_minimum_size = Vector2(460, 0)
	vb.add_theme_constant_override("separation", 14)
	glass.add_child(vb)

	# Avatar
	var avatar_holder := CenterContainer.new()
	vb.add_child(avatar_holder)
	if user_icon:
		var tr := TextureRect.new()
		tr.texture = user_icon
		tr.custom_minimum_size = Vector2(110, 110)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		avatar_holder.add_child(tr)
	else:
		var av := Panel.new()
		av.custom_minimum_size = Vector2(110, 110)
		av.add_theme_stylebox_override("panel", _flat(Color(0.25, 0.3, 0.5), 55))
		avatar_holder.add_child(av)

	vb.add_child(_label(workstation_name, 30, Color(0.92, 0.93, 0.97)))

	_pw_edit = LineEdit.new()
	_pw_edit.placeholder_text = "Enter Password..."
	_pw_edit.secret = true
	_pw_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_pw_edit.custom_minimum_size = Vector2(0, 52)
	_pw_edit.add_theme_font_size_override("font_size", 22)
	_pw_edit.add_theme_stylebox_override("normal", _flat(Color(0.55, 0.63, 0.78, 0.75), 14))
	_pw_edit.add_theme_stylebox_override("focus", _flat(Color(0.6, 0.68, 0.85, 0.9), 14, Color.WHITE, 2))
	if ui_font:
		_pw_edit.add_theme_font_override("font", ui_font)
	_pw_edit.text_submitted.connect(_try_login)
	vb.add_child(_pw_edit)

	var unlock := _button("Unlock Computer")
	unlock.custom_minimum_size = Vector2(0, 52)
	unlock.add_theme_stylebox_override("normal", _flat(Color(0.28, 0.4, 0.74), 14))
	unlock.add_theme_stylebox_override("hover", _flat(Color(0.34, 0.47, 0.82), 14))
	unlock.add_theme_stylebox_override("pressed", _flat(Color(0.22, 0.33, 0.62), 14))
	unlock.pressed.connect(_try_login)
	vb.add_child(unlock)

	_pw_error = _label("", 20, ERROR_RED)
	_pw_error.custom_minimum_size = Vector2(0, 28)
	vb.add_child(_pw_error)

	return page


func _build_desktop() -> Control:
	var page := Control.new()
	var bg := _background(desktop_background, Color(0.12, 0.13, 0.26))
	page.add_child(bg)
	_full(bg)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_top", 30)
	page.add_child(margin)
	_full(margin)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 20)
	margin.add_child(col)

	col.add_child(_desktop_icon("Recycle Bin", recycle_icon, Color(0.8, 0.78, 0.68), _on_recycle))
	col.add_child(_desktop_icon("Folder #1", folder_icon, Color(0.3, 0.45, 0.85), _on_folder))
	col.add_child(_desktop_icon("Locked_Archive", locked_folder_icon, Color(0.9, 0.85, 0.3), _on_archive))
	return page


func _desktop_icon(text: String, icon: Texture2D, tint: Color, cb: Callable) -> Button:
	var b := _button(text)
	b.custom_minimum_size = Vector2(150, 110)
	b.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	if icon:
		b.flat = true
		b.icon = icon
		b.expand_icon = true
		b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	else:
		b.add_theme_stylebox_override("normal", _flat(tint.darkened(0.45), 10))
		b.add_theme_stylebox_override("hover", _flat(tint.darkened(0.25), 10))
		b.add_theme_stylebox_override("pressed", _flat(tint.darkened(0.55), 10))
	b.pressed.connect(cb)
	return b


func _open_code_dialog() -> void:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(720, 0)
	var ps := _flat(Color(0.11, 0.14, 0.28), 24, Color(0.2, 0.25, 0.45), 2)
	ps.set_content_margin_all(40)
	panel.add_theme_stylebox_override("panel", ps)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 16)
	panel.add_child(vb)

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 20)
	vb.add_child(head)

	var lock := PanelContainer.new()
	lock.custom_minimum_size = Vector2(90, 90)
	lock.add_theme_stylebox_override("panel", _flat(Color(0.62, 0.52, 0.22), 16))
	lock.add_child(_label("LOCK", 18, Color(1.0, 0.85, 0.1)))
	head.add_child(lock)

	var titles := VBoxContainer.new()
	titles.alignment = BoxContainer.ALIGNMENT_CENTER
	titles.add_child(_label("Locked_Archive", 28, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT))
	titles.add_child(_label("Security Code Required", 20, Color(0.8, 0.85, 1.0), HORIZONTAL_ALIGNMENT_LEFT))
	head.add_child(titles)

	vb.add_child(HSeparator.new())
	vb.add_child(_label("Enter the 4-digit code to decrypt this file.", 20, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT))

	_code_edit = LineEdit.new()
	_code_edit.placeholder_text = "_ _ _ _"
	_code_edit.max_length = 4
	_code_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_code_edit.custom_minimum_size = Vector2(0, 60)
	_code_edit.add_theme_font_size_override("font_size", 30)
	_code_edit.add_theme_stylebox_override("normal", _flat(Color(0.08, 0.08, 0.18), 30))
	_code_edit.add_theme_stylebox_override("focus", _flat(Color(0.08, 0.08, 0.18), 30, Color(0.4, 0.5, 0.9), 2))
	if ui_font:
		_code_edit.add_theme_font_override("font", ui_font)
	_code_edit.text_changed.connect(_filter_digits)
	_code_edit.text_submitted.connect(_try_code)
	vb.add_child(_code_edit)

	_code_error = _label("", 20, ERROR_RED)
	_code_error.custom_minimum_size = Vector2(0, 28)
	vb.add_child(_code_error)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_END
	row.add_theme_constant_override("separation", 20)
	var cancel := _button("Cancel")
	cancel.pressed.connect(_close_popup)
	var ok := _button("Ok")
	ok.pressed.connect(_try_code)
	row.add_child(cancel)
	row.add_child(ok)
	vb.add_child(row)

	_show_popup(panel)
	_code_edit.grab_focus()


## Retro "window" with title bar and File/Edit/View/Help row. Returns its body.
func _open_window(title: String) -> VBoxContainer:
	var win := PanelContainer.new()
	win.custom_minimum_size = Vector2(760, 0)
	var ws := _flat(Color(0.86, 0.87, 0.94), 0, Color(0.27, 0.29, 0.45), 3)
	ws.set_content_margin_all(0)
	win.add_theme_stylebox_override("panel", ws)

	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 0)
	win.add_child(outer)

	var bar := PanelContainer.new()
	bar.add_theme_stylebox_override("panel", _flat(Color(0.27, 0.29, 0.45), 0))
	bar.add_child(_label(title, 18, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT))
	outer.add_child(bar)

	var menu := PanelContainer.new()
	menu.add_theme_stylebox_override("panel", _flat(Color(0.66, 0.69, 0.86), 0))
	var mh := HBoxContainer.new()
	mh.add_theme_constant_override("separation", 26)
	for t in ["File", "Edit", "View", "Help"]:
		mh.add_child(_label(t, 16, DARK_TEXT, HORIZONTAL_ALIGNMENT_LEFT))
	menu.add_child(mh)
	outer.add_child(menu)

	var pad := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		pad.add_theme_constant_override("margin_" + side, 36)
	outer.add_child(pad)

	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 18)
	pad.add_child(body)

	_show_popup(win)
	return body


func _show_popup(content: Control) -> void:
	_close_popup()
	_popup = Control.new()
	_root.add_child(_popup)
	_full(_popup)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.5)
	_popup.add_child(dim)
	_full(dim)

	var center := CenterContainer.new()
	_popup.add_child(center)
	_full(center)
	center.add_child(content)


func _close_popup() -> void:
	if _popup:
		_popup.queue_free()
		_popup = null


# ------------------------------------------------------------ helpers --------
func _full(c: Control) -> void:
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _background(tex: Texture2D, fallback: Color) -> Control:
	if tex:
		var tr := TextureRect.new()
		tr.texture = tex
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		return tr
	var cr := ColorRect.new()
	cr.color = fallback
	return cr


func _flat(color: Color, radius: int = 12, border: Color = Color(0, 0, 0, 0), border_w: int = 0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.set_corner_radius_all(radius)
	s.set_border_width_all(border_w)
	s.border_color = border
	s.set_content_margin_all(10)
	return s


func _label(text: String, size: int, color: Color = Color.WHITE, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER, wrap: bool = false) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = align
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if ui_font:
		l.add_theme_font_override("font", ui_font)
	if wrap:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(640, 0)
	return l


func _button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(110, 40)
	b.add_theme_font_size_override("font_size", 20)
	if ui_font:
		b.add_theme_font_override("font", ui_font)
	return b


func _ok_button(cb: Callable) -> Button:
	var b := _button("Ok")
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.pressed.connect(cb)
	return b
