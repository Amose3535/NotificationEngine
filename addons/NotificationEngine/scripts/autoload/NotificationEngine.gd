# NotificationEngine.gd
extends Node

#region SIGNALS
@warning_ignore("unused_signal")
signal notif_popup(notification : Control)
@warning_ignore("unused_signal")
signal notif_popout(notification : Control)
signal notification_action(notification: Control, notif_id : int, action_id : String)
#endregion

#region INTERNALS
enum SIDE {BOTTOM_RIGHT,BOTTOM_LEFT}
var LOCATION : SIDE = SIDE.BOTTOM_RIGHT
const NOTIFICATION : PackedScene = preload("res://addons/NotificationEngine/scenes/notification.tscn")
const THEMES := {"default":preload("res://addons/NotificationEngine/resources/themes/default.tres")}
const CHECK_INTERVAL : float = 0.5
var CURRENT_TIME : float = 0.0
#endregion

#region UTILITIES
var root : CanvasLayer # TODO (maybe): Turn root into an always-on-top, transparent, borderless window 
					   #               so notifications can be seen outside of the main window
var spacing : int = 5:
	set(new_spacing):
		_reflow_bottom_to_top()
#endregion

func _ready() -> void:
	get_window().size_changed.connect(_on_window_size_changed)
	# Prepare the global overlay where notifications live across scene changes
	root = CanvasLayer.new()
	root.name = "NotificationsRoot"
	root.layer = 100
	if not get_tree().root.has_node("NotificationsRoot"):
		get_tree().root.add_child.call_deferred(root)
	else:
		print("NotificationsRoot not instantiated: node already exists.")
		root = get_tree().root.get_node("NotificationsRoot")

func _process(delta: float) -> void:
	CURRENT_TIME += delta
	# Visibility check every 0.5s (lightweight guard, not strict)
	if CURRENT_TIME >= CHECK_INTERVAL:
		CURRENT_TIME -= CHECK_INTERVAL
		
		var total_y : int = 0
		var notification_number : int = 0
		
		# Sum only Control children (defensive)
		for child in root.get_children():
			if child is Control:
				total_y += child.size.y
				notification_number += 1
		
		if total_y + (notification_number - 1) * spacing > get_window().get_visible_rect().size.y:
			push_warning("VISIBILITY WARNING: The notification stack exceeds viewport height.")

# API for notification calls
func notify(payload : Dictionary) -> void:
	# 1) Create the new notification node
	var new_notif : Control = NOTIFICATION.instantiate()
	
	# 2) Makes notification transparent to prevent it showing for a split second
	new_notif.modulate = Color(1,1,1,0)
	
	# 3) Add to root first so layout becomes valid
	root.add_child(new_notif)
	
	# 4) Wait 1 frame to allow children to be correctly instanced before assigning values to variables
	#    (prevents crashes and/or incorrect formatting)
	await get_tree().process_frame
	
	# 5) Unpack payload
	_extract_payload(payload, new_notif)
	
	# 6) Wait 1 frame so size.x/size.y are correct before positioning/tweening
	await get_tree().process_frame
	
	# 7) Connect action notification signal to engine's function for re-emission
	new_notif.connect("action_triggered",_on_notification_action)
	
	# 8) Vertical absolute reflow for ALL items (including the new one)
	_reflow_bottom_to_top()
	
	# 9) Start the notification (in → wait → out → free)
	new_notif.start_notification()

# API for setting the spacing (reflows automatically through spacing's setter
func set_spacing(new_spacing : float) -> void:
	spacing = new_spacing

# API for setting alignment (NOTE: notification alignment is applied only to the NEXT notifications)
func set_alignment(mode : SIDE) -> void:
	if mode is SIDE:
		LOCATION = mode

# API for getting alignment
func get_alignment() -> SIDE:
	return LOCATION

# Extracts all payload parameters onto the target notification in a modular manner
func _extract_payload(payload : Dictionary, target_notif : Control) -> void:
	# NOTE: 
	#		The notification scene hides every customizable element until it is set through the setter.
	#		Setting ANY parameter (other than the two durations) WILL make that element visible so don't do what i did for "title"
	#		unless you know what you're doing.
	#		(i'm watching you)
	
	
	# Set the title
	if payload.has("title"):
		var title_candidate := payload.get("title")
		if title_candidate is String and (title_candidate != "" or title_candidate != null):
			target_notif.title_content = title_candidate
	else:
		target_notif.title_content = "No title provided"
	
	# Set the icon
	if payload.has("icon"):
		var icon_candidate := payload.get("icon")
		if icon_candidate is Texture2D and icon_candidate != null:
			target_notif.icon = icon_candidate
	
	# Set the body
	if payload.has("body"):
		var body_candidate := payload.get("body")
		if body_candidate is String:
			target_notif.body_content = body_candidate
	
	# Set the actions
	if payload.has("actions"):
		var actions_candidate := payload.get("actions")
		if actions_candidate is Array:
			target_notif.actions = actions_candidate
	
	# Set the theme
	if payload.has("theme"):
		var theme_candidate := payload.get("theme")
		# Check wether the format is String
		if theme_candidate is String:
			# If it is, check if the wanted theme string is present in the presets
			if THEMES.has(theme_candidate):
				# If it is, apply the wanted theme to the target notification
				target_notif.theme = THEMES[theme_candidate]
		
		# Check wether the format is Theme
		if theme_candidate is Theme:
			# If so apply that theme directly to the target notification
			target_notif.theme = theme_candidate
	
	# Set the duration
	if payload.has("duration"):
		var duration_candidate := payload.get("duration")
		match typeof(duration_candidate):
			2: # int
				if duration_candidate > 0:
					target_notif.duration_seconds = float(duration_candidate)
				
			
			3: # float
				if duration_candidate > 0.0:
					target_notif.duration_seconds = duration_candidate
			
			4: # String
				if (duration_candidate as String).is_valid_float():
					if (duration_candidate as String).to_float() > 0.0:
						target_notif.duration_seconds = (duration_candidate as String).to_float()
	
	# Set the animations duration
	if payload.has("animation_duration"):
		var anim_dur_candidate := payload.get("animation_duration")
		match typeof(anim_dur_candidate):
			2: # int
				if anim_dur_candidate > 0:
					target_notif.animation_duration = float(anim_dur_candidate)
			
			3: # float
				if anim_dur_candidate > 0:
					target_notif.animation_duration = anim_dur_candidate
			
			4: # String
				if (anim_dur_candidate as String).is_valid_float():
					if (anim_dur_candidate as String).to_float() > 0.0:
						target_notif.animation_duration = (anim_dur_candidate as String).to_float()

# Frees the notification and reflows the others (bottom → top)
func _free_notification(notif : Node) -> void:
	if not is_instance_valid(notif):
		return
	if root == null:
		return
	
	# Disconnect "action_triggered" from on_notification_action_pressed to avoid possible errors
	if notif.is_connected("action_triggered", _on_notification_action):
		notif.disconnect("action_triggered",_on_notification_action)
	
	# Defer the free to avoid modifying the tree mid-iteration
	notif.call_deferred("queue_free")
	
	# Next frame do a clean absolute reflow
	await get_tree().process_frame
	_reflow_bottom_to_top()

# Absolute reflow from bottom to top, including a bottom margin == spacing
func _reflow_bottom_to_top() -> void:
	# Snapshot & filter (Control only)
	var items : Array[Control] = []
	for child in root.get_children():
		if child is Control:
			items.append(child)
	
	# Newest are appended last → reverse to place from bottom upward
	items.reverse()
	
	var window_height        : float = get_window().get_visible_rect().size.y
	var notification_spacing : float = spacing   # the space between notifications
	var bottom_margin        : float = spacing   # keep a consistent "breathing" space at the bottom
	
	var accumulative_y : float = 0.0
	var anim_dur : float = 0.3  # single, consistent reflow duration
	
	for notif in items:
		var notif_height : float = notif.size.y
		# bottom-attached layout: start at the bottom (window_height) and subtract the margin, the notification height itself
		# and the current accumulated space
		var target_y : float = window_height - bottom_margin - accumulative_y - notif_height
		
		var tween : Tween = get_tree().create_tween()
		tween.set_trans(Tween.TRANS_QUAD)
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(notif, "position:y", target_y, anim_dur)
		
		accumulative_y += notif_height + notification_spacing

# When the size of the window changes reflow the notification elements
func _on_window_size_changed() -> void:
	_reflow_bottom_to_top()

# Function that emits "notification_action" signal with all the correct parameters
func _on_notification_action(notification : Control, notif_id : int, action_id : String):
	self.emit_signal("notification_action",notification,notif_id,action_id)
