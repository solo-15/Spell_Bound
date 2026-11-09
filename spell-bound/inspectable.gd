extends StaticBody3D
class_name Inspectable

@export var prompt: String = "Inspect"
@export var title: String = "Item"
@export_multiline var body: String = "You look closely..."
@export_multiline var already_checked_body: String = "You already searched here. Nothing else."

@export_group("Letter (optional)")
@export_range(0, 4) var letter_slot: int = 0   # 0 = this object has no letter
@export var letter: String = ""

@export_group("Locking (optional)")
@export var required_flag: StringName = &""    # e.g. "has_key"
@export_multiline var locked_body: String = "It's locked."
@export var sets_flag: StringName = &""        # flag given when inspected (e.g. a key)


func get_prompt() -> String:
	return prompt


func interact() -> void:
	# Locked until the player has the required flag (e.g. a key)
	if required_flag != &"" and not GameState.has_flag(required_flag):
		GameState.show_message(title, locked_body)
		return

	if sets_flag != &"":
		GameState.set_flag(sets_flag)

	# Letter objects only give their letter once
	if letter_slot > 0 and GameState.has_letter(letter_slot):
		GameState.show_message(title, already_checked_body)
		return

	GameState.show_message(title, body, letter_slot, letter)
