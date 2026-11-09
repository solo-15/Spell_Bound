extends Node3D

@export var open_distance := 0.5
@export var speed := 3.0

var is_open = false
var closed_pos : Vector3
var open_pos : Vector3

func _ready():
	closed_pos = position
	open_pos = closed_pos + Vector3(0, 0, open_distance)

func _process(delta):
	var target = open_pos if is_open else closed_pos
	position = position.lerp(target, speed * delta)

func toggle_drawer():
	is_open = !is_open
	print("Drawer toggled")
