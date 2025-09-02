# action.gd
extends Button

# Have a local signal used to tell the system that a button with action id "id" has been pressed
signal action_button_pressed(action_id : String)

var id : String = ""

func _ready() -> void:
	self.pressed.connect(_on_action_button_pressed)

func _on_action_button_pressed() -> void:
	self.emit_signal("action_button_pressed",id)
