extends "res://globals/scene_base.gd"

# https://commons.wikimedia.org/wiki/File:Emoji_u1f590_1f3fb.svg
var handIcon = load("res://globals/actor/Emoji_u1f590_1f3fb.png")

func _ready():
	Input.set_custom_mouse_cursor(handIcon)
