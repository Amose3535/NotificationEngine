# Notification.gd
extends PanelContainer
class_name NotificationView

const ACTION_BUTTON = preload("res://addons/NotificationEngine/scenes/action_button.tscn")

signal action_triggered(notification : Control, notif_id : int, action_id : String)

@onready var title: RichTextLabel = $VBoxContainer/Header/MarginContainer/HBoxContainer/Title
@onready var close: Button = $VBoxContainer/Header/MarginContainer/HBoxContainer/close
@onready var image: TextureRect = $VBoxContainer/Body/BodyStack/BodyContent/Icon
@onready var body: RichTextLabel = $VBoxContainer/Body/BodyStack/BodyContent/Body
@onready var actions_container: HFlowContainer = $VBoxContainer/Body/BodyStack/actions_container
@onready var audio_container: Node = $AudioContainer



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
						
						# Allow the button to dismiss a notification on click (OPT)
						if element.has("dismiss") and element.get("dismiss") is bool:
							new_button.can_dismiss = element["dismiss"]
						
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

var duration_seconds : float = 3.0 # Total notification lifespan (s)

var animation_duration : float = 0.3 # Animation length (s)

var sounds : Dictionary:
	set(new_sounds):
		# Cleans the actions container from all possible residues
		_in_player = null
		_out_player = null
		_close_player = null
		_action_player = null
		for child in audio_container.get_children(): child.queue_free()
		
		_apply_sound("in",new_sounds,sounds)
		
		_apply_sound("out",new_sounds,sounds)
		
		_apply_sound("close",new_sounds,sounds)
		
		_apply_sound("action",new_sounds,sounds)
#endregion

var _started : bool = false
var alignment
var _ending : bool = false
var _timer : Timer
# Audio
var _in_player : AudioStreamPlayer
var _out_player : AudioStreamPlayer
var _close_player : AudioStreamPlayer
var _action_player : AudioStreamPlayer

func _ready() -> void:
	# Connect signals such as mouse_entered, exited and the pressed signal from the close button.
	connect("mouse_entered", _on_mouse_entered)
	connect("mouse_exited", _on_mouse_exited)
	close.connect("pressed",_on_close_pressed)
	# Create the timer to be used later on.
	_timer = Timer.new()
	_timer.one_shot = true
	self.add_child(_timer)


func start_notification() -> void:
	if _started: return
	_started = true
	var persistent : bool = false
	if duration_seconds <= 0.0: persistent = true
	# Saves a local copy of the alignment to prevent animations mismatch during the whole process
	alignment = NotificationEngine.get_alignment()
	
	# Play popup sound
	if _in_player != null:
		_in_player.play()
	
	# Saves a local copy of the window size
	var window_size : Vector2 = get_window().get_visible_rect().size
	match alignment:
		NotificationEngine.SIDE.BOTTOM_RIGHT:
			# Start off-screen on the right
			position = Vector2(window_size.x, window_size.y - size.y - NotificationEngine.spacing)
		
		NotificationEngine.SIDE.BOTTOM_LEFT:
			# Start off-screen on the left
			position = Vector2(-size.x, window_size.y - size.y - NotificationEngine.spacing)
	
	# Ensure layout is ready (size is valid)
	await get_tree().process_frame
	
	# Fade from transparent
	modulate = Color(1, 1, 1, 0)
	
	# IN: slide + fade in (EASE_OUT feels more natural)
	var final_in_x_pos : float = 0
	var in_tween : Tween = get_tree().create_tween()
	in_tween.set_ease(Tween.EASE_OUT)
	
	# Determine final "in" position based on L/R preset
	if alignment == NotificationEngine.SIDE.BOTTOM_RIGHT:
		final_in_x_pos = position.x - size.x
	elif alignment == NotificationEngine.SIDE.BOTTOM_LEFT:
		final_in_x_pos = position.x + size.x
	
	in_tween.tween_property(self, "position:x", final_in_x_pos, animation_duration)
	in_tween.set_parallel()
	in_tween.tween_property(self, "modulate", Color(1, 1, 1, 1), animation_duration)
	
	# Emit popup signal (duration info for listeners)
	NotificationEngine.emit_signal("notif_popup", self)
	
	# Start pausable timer
	if !persistent:
		_timer.start(duration_seconds)
		print(duration_seconds)
		await _timer.timeout
		
		end_notification()

func end_notification() -> void:
	if _ending: return
	_ending = true
	
	# Play popout sound
	if _out_player != null:
		_out_player.play()
	
	# OUT: slide right + fade out (EASE_IN for a clean exit)
	var final_out_x_pos : float = 0
	var out_tween : Tween = get_tree().create_tween()
	out_tween.set_ease(Tween.EASE_IN)
	
		# Determine final "out" position based on L/R preset
	if alignment == NotificationEngine.SIDE.BOTTOM_RIGHT:
		final_out_x_pos = position.x + size.x
	elif alignment == NotificationEngine.SIDE.BOTTOM_LEFT:
		final_out_x_pos = position.x - size.x
	
	out_tween.tween_property(self, "position:x", final_out_x_pos, animation_duration)
	out_tween.set_parallel()
	out_tween.tween_property(self, "modulate", Color(1, 1, 1, 0), animation_duration)
	
	await out_tween.finished
	
	# Emit popout signal, then ask the engine to free and reflow
	NotificationEngine.emit_signal("notif_popout", self)
	NotificationEngine._free_notification(self)

func dismiss() -> void:
	if _close_player != null:
		_close_player.play()
	end_notification()

# key: "in" | "out" | "action" | "close"
# new_sounds: new dict (payload.sounds)
# prev: prev dict (es. la tua prop `sounds`)
# global (opz): global fallback (if present, otherwise will use previous as fallback and nun more)
func _apply_sound(key: String, new_sounds: Dictionary, prev: Dictionary, global: Dictionary = {}) -> void:
	# 1) helper to access the correct player
	var player
	match key:
		"in": player=_in_player
		"out": player=_out_player
		"action": player=_action_player
		"close": player=_close_player
		_:
			if NotificationEngine.LOGGING:
				push_warning("[NotificationEngine/Notification] | Sound module: unknown key '%s' (ignored)" % key)
			return
	
	# 2) kill/clear previous player precedente for that key
	if is_instance_valid(player):
		player.queue_free()
	match key:
		"in": _in_player = null
		"out": _out_player = null
		"action": _action_player = null
		"close": _close_player = null
	
	# internal reusable function to create the player
	var make_player = func _make_player(stream: AudioStream) -> void:
		var p := AudioStreamPlayer.new()
		p.name = "sound_%s" % key
		p.stream = stream
		# opt: set the bus if used
		# p.bus = "UI"
		audio_container.add_child(p)
		match key:
			"in": _in_player = p
			"out": _out_player = p
			"action": _action_player = p
			"close": _close_player = p
	
	# 3) APPLY / CLEAR / INVALID → fallback
	var has_key := new_sounds.has(key)
	if has_key:
		var v = new_sounds[key]
		if v is AudioStream:
			make_player.call(v)
			if NotificationEngine.LOGGING:
				print("[NotificationEngine/Notification] | Sound %s: APPLY (payload)" % key)
			return
		elif v == null:
			# Explicit CLEAR: no fallback
			if NotificationEngine.LOGGING:
				print("[NotificationEngine/Notification] | Sound %s: CLEAR (null)" % key)
			return
		else:
			if NotificationEngine.LOGGING:
				push_warning("[NotificationEngine/Notification] | Sound %s: INVALID_TYPE (%s) → fallback" % [key, typeof(v)])
			# continue and then fallback
	
	# 4) Fallback: prev → global → silence
	if prev.has(key) and prev[key] is AudioStream:
		make_player.call(prev[key])
		if NotificationEngine.LOGGING:
			print("[NotificationEngine/Notification] | Sound %s: APPLY (prev)" % key)
		return
	
	# There is a sound for this key
	if global != null and global.has(key) and global[key] is AudioStream:
		make_player.call(global[key])
		if NotificationEngine.LOGGING:
			print("[NotificationEngine/Notification] | Sound %s: APPLY (global)" % key)
		return
	
	# No sound for this key
	if NotificationEngine.LOGGING:
		print("[NotificationEngine/Notification] | Sound %s: SILENCE (no fallback)" % key)

func _on_mouse_entered() -> void:
	_timer.paused = true

func _on_mouse_exited() -> void:
	_timer.paused = false

func _on_close_pressed() -> void:
	dismiss()

func _on_action_button_pressed(action_id : String, can_dismiss : bool) -> void:
	self.emit_signal("action_triggered",self,notification_id,action_id)
	if _action_player != null:
		_action_player.play()
	if can_dismiss:
		dismiss()
