extends Control

const ICON = preload("res://icon.svg")
@onready var button: Button = $Button
@onready var button_2: Button = $Button2
@onready var button_3: Button = $Button3

func _ready() -> void:
	button.connect("pressed",_on_button_pressed)
	button_2.connect("pressed",_on_button_2_pressed)
	button_3.connect("pressed",_on_button_3_pressed)
	NotificationEngine.connect("notification_action",_on_notification_action)

func _on_button_pressed():
	NotificationEngine.notify({
		"title":"Demo",
		"body":"Demo Body:\nLorem [b]ipsum[/b] [i]dolor[/i] sit amet",
		"duration":5.0,
		"animation_duration":0.2
		})

func _on_button_2_pressed():
	NotificationEngine.notify({
		"title":"Demo",
		"icon" : ICON,
		"body":"Demo Body:\nLorem [b]ipsum[/b] [i]dolor[/i] sit amet",
		"duration":5.0,
		"animation_duration":0.2
		})

func _on_button_3_pressed():
	NotificationEngine.notify({
		"title":"Demo ACTIONS",
		"body":"Demo Body:\nLorem [b]ipsum[/b] [i]dolor[/i] sit amet",
		"actions":[{"id":"action_1","label":"ACTION 1"},{"id":"action_2","label":"ACTION 2","icon":ICON}],
		"duration":5.0,
		"animation_duration":0.2
		})

func _on_notification_action(notification_node : Control, notif_id : int, action_id : String) -> void:
	match action_id:
		"action_1":
			NotificationEngine.set_alignment(NotificationEngine.SIDE.BOTTOM_LEFT)
		"action_2":
			NotificationEngine.set_alignment(NotificationEngine.SIDE.BOTTOM_RIGHT)
