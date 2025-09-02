# Notification.gd
extends PanelContainer
#class_name NotificationPanel

const ACTION_BUTTON = preload("res://addons/NotificationEngine/scenes/action_button.tscn")

signal action_triggered(notification : Control, notif_id : int, action_id : String)

@onready var title: RichTextLabel = $VBoxContainer/Header/MarginContainer/Title
@onready var image: TextureRect = $VBoxContainer/Body/BodyStack/BodyContent/Icon
@onready var body: RichTextLabel = $VBoxContainer/Body/BodyStack/BodyContent/Body
@onready var actions_container: HFlowContainer = $VBoxContainer/Body/BodyStack/actions_container


@onready var notification_id : int = self.get_instance_id()

#region Notification parameters
var title_content : String = "" :
	set(new_title):
		if title != null:
			title.show()
			title.set_deferred("text",new_title)

var icon : Texture2D:
	set(new_icon):
		if image != null:
			image.show()
			image.set_deferred("texture",new_icon)

var body_content : String = "" :
	set(new_body):
		if body != null:
			body.show()
			body.set_deferred("text",new_body)

var actions : Array:    # ex: [{ "id":"ok", "label":"OK", "icon":icon_texture}]
	set(new_actions):
		# Cleans the actions container from all possible residues
		for child in actions_container.get_children(): child.queue_free()
		actions_container.hide()
		
		var container_isvalid : bool = false
		for element in new_actions:
			if element is Dictionary:
				# For an action element to be considered valid it has to have at least an "id" and a "label" and their values should be Strings
				if (element.has("id") and element.has("label")) and (element.get("id") is String and element.get("label") is String):
					var new_button : Button
					if element["label"] is String and element["id"] is String:
						if !container_isvalid:
							container_isvalid = true
							
						new_button = ACTION_BUTTON.instantiate()
						actions_container.add_child(new_button)
						new_button.text = element["label"]
						new_button.id =  element["id"]
						
						# Set the icon only if the action element has an icon part (makin icon optional)
						if element.has("icon") and element.get("icon") is Texture2D:
							new_button.icon = element["icon"]
						# If on the button there's an icon but no text -> icon centered
						if new_button.text == "" and new_button.icon != null:
							new_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
							new_button.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
							new_button.expand_icon = false
						# If on the button there's both some text and an icon -> icon left
						if new_button.text != "" and new_button.icon != null:
							new_button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
							new_button.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
							new_button.expand_icon = true
						
						new_button.connect("action_button_pressed",_on_action_button_pressed)
			
		# IF there is AT LEAST one valid button in the actions container show the container
		if container_isvalid:
			actions_container.show()

var duration_seconds    : float = 3.0 # Total notification lifespan (s)

var animation_duration  : float = 0.3 # Animation length (s)

#endregion

var _started : bool = false

func _ready() -> void:
	# Do not rely on size here (layout may not be ready).
	# We'll offset in start_notification() after 1 frame.
	pass

func start_notification() -> void:
	if _started:
		return
	_started = true
	
	var window_size : Vector2 = get_window().get_visible_rect().size
	match NotificationEngine.LOCATION:
		NotificationEngine.SIDE.BOTTOM_RIGHT:
			# Start off-screen on the right
			position = Vector2(window_size.x, window_size.y - size.y - NotificationEngine.spacing)
		
		NotificationEngine.SIDE.BOTTOM_LEFT:
			# Start off-screen on the left
			position = Vector2( -size.x, window_size.y - size.y - NotificationEngine.spacing)
	
	# Ensure layout is ready (size is valid)
	await get_tree().process_frame
	
	# Fade from transparent
	modulate = Color(1, 1, 1, 0)
	
	
	
	# IN: slide + fade in (EASE_OUT feels more natural)
	var final_in_x_pos : float = 0
	var in_tween : Tween = get_tree().create_tween()
	in_tween.set_ease(Tween.EASE_OUT)
	
	# Determine final "in" position based on L/R preset
	if NotificationEngine.LOCATION == NotificationEngine.SIDE.BOTTOM_RIGHT:
		final_in_x_pos = position.x - size.x
	elif NotificationEngine.LOCATION == NotificationEngine.SIDE.BOTTOM_LEFT:
		final_in_x_pos = position.x + size.x
	
	in_tween.tween_property(self, "position:x", final_in_x_pos, animation_duration)
	in_tween.set_parallel()
	in_tween.tween_property(self, "modulate", Color(1, 1, 1, 1), animation_duration)
	
	# Emit popup signal (duration info for listeners)
	NotificationEngine.emit_signal("notif_popup", duration_seconds)
	
	# Visible for duration
	await get_tree().create_timer(duration_seconds).timeout
	
	# OUT: slide right + fade out (EASE_IN for a clean exit)
	var final_out_x_pos : float = 0
	var out_tween : Tween = get_tree().create_tween()
	out_tween.set_ease(Tween.EASE_IN)
	
		# Determine final "out" position based on L/R preset
	if NotificationEngine.LOCATION == NotificationEngine.SIDE.BOTTOM_RIGHT:
		final_out_x_pos = position.x + size.x
	elif NotificationEngine.LOCATION == NotificationEngine.SIDE.BOTTOM_LEFT:
		final_out_x_pos = position.x - size.x
	
	out_tween.tween_property(self, "position:x", final_out_x_pos, animation_duration)
	out_tween.set_parallel()
	out_tween.tween_property(self, "modulate", Color(1, 1, 1, 0), animation_duration)
	
	await out_tween.finished
	
	# Emit popout signal, then ask the engine to free and reflow
	NotificationEngine.emit_signal("notif_popout")
	NotificationEngine.free_notification(self)

func _on_action_button_pressed(action_id : String) -> void:
	self.emit_signal("action_triggered",self,notification_id,action_id)
