# Notification.gd
extends PanelContainer

@onready var title : RichTextLabel = $VBoxContainer/Header/MarginContainer/Title
@onready var body  : RichTextLabel = $VBoxContainer/MarginContainer/Body

#region Notification parameters
var title_content : String = "" :
	set(new_title):
		if title != null:
			title.set_deferred("text",new_title)

var body_content : String = "" :
	set(new_body):
		if body != null:
			body.set_deferred("text",new_body)
		

var duration_seconds    : float = 1.0
var animation_duration  : float = 0.3

var icon    : Texture2D            # UNUSED for now
var actions : Array[Dictionary]    # UNUSED for now. ex: [{ "id":"ok", "label":"OK" }]
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
	
	# Ensure layout is ready (size is valid)
	await get_tree().process_frame
	
	# Start off-screen to the right (bottom-right anchoring is set in the scene)
	position.x += size.x
		
	
	# Fade from transparent
	modulate = Color(1, 1, 1, 0)
	
	# IN: slide left + fade in (EASE_OUT feels more natural)
	var in_tween : Tween = get_tree().create_tween()
	in_tween.set_ease(Tween.EASE_OUT)
	in_tween.tween_property(self, "position:x", position.x - size.x, animation_duration)
	in_tween.set_parallel()
	in_tween.tween_property(self, "modulate", Color(1, 1, 1, 1), animation_duration)
	
	# Emit popup signal (duration info for listeners)
	NotificationEngine.emit_signal("notif_popup", duration_seconds)
	
	# Visible for duration
	await get_tree().create_timer(duration_seconds).timeout
	
	# OUT: slide right + fade out (EASE_IN for a clean exit)
	var out_tween : Tween = get_tree().create_tween()
	out_tween.set_ease(Tween.EASE_IN)
	out_tween.tween_property(self, "position:x", position.x + size.x, animation_duration)
	out_tween.set_parallel()
	out_tween.tween_property(self, "modulate", Color(1, 1, 1, 0), animation_duration)
	
	await out_tween.finished
	
	# Emit popout signal, then ask the engine to free and reflow
	NotificationEngine.emit_signal("notif_popout")
	NotificationEngine.free_notification(self)
