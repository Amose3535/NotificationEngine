# NotificationEngine.gd
@tool
extends Node

#region SIGNALS
@warning_ignore("unused_signal")
signal notif_popup(notification : Control)
@warning_ignore("unused_signal")
signal notif_popout(notification : Control)
signal notification_action(notification: Control, notif_id : int, action_id : String)
#endregion

#region INTERNALS
var DEFAULT_PAYLOAD : Payload = null
var DEFAULT_PAYLOAD_PATH : String = "user://NotificationEngine/DEFAULT_PAYLOAD.tres"

enum SIDE {BOTTOM_RIGHT,BOTTOM_LEFT}
var LOCATION : SIDE = SIDE.BOTTOM_RIGHT

const NOTIFICATION : PackedScene = preload("res://addons/NotificationEngine/scenes/notification.tscn")

const THEMES := {"default":preload("res://addons/NotificationEngine/resources/themes/default.tres")}

var LOGGING : bool = false

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
	
	# If the directory with the useful files doesn't exist (deleted or first run)
	if !DirAccess.dir_exists_absolute(DEFAULT_PAYLOAD_PATH.get_base_dir()):
		# Create the directory for all the useful files to be saved in
		DirAccess.make_dir_absolute(DEFAULT_PAYLOAD_PATH.get_base_dir())
	
	# Get default Payload if present
	if FileAccess.file_exists(DEFAULT_PAYLOAD_PATH):
		var p_candidate = load(DEFAULT_PAYLOAD_PATH)
		# Safe payload extraction
		DEFAULT_PAYLOAD = Payload.new(p_candidate)

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

#region API
# API for notification calls
func notify(payload : Variant) -> void:
	# 1) Create the new notification node
	var new_notif : Control = NOTIFICATION.instantiate()
	
	# 2) Makes notification transparent to prevent it showing for a split second
	new_notif.modulate = Color(1,1,1,0)
	
	# 3) Add to root first so layout becomes valid
	root.add_child(new_notif)
	
	# 4) Wait 1 frame to allow children to be correctly instanced before assigning values to variables
	#    (prevents crashes and/or incorrect formatting)
	await get_tree().process_frame
	
	# 5) Apply default payload only if there is one applied
	if DEFAULT_PAYLOAD != null:
		_extract_payload(DEFAULT_PAYLOAD, new_notif)
	else:
		if LOGGING:
			print("[NotificationEngine] | Notify: Default payload missing; skipping entirely.")
	
	# 6) Override default payload with custom one
	_extract_payload(payload, new_notif)
	#print(payload["sounds"]) # OK
	#print(new_notif.sounds) # NOT OK!!! => Error during extraction
	
	# 7) Wait 1 frame so size.x/size.y are correct before positioning/tweening
	await get_tree().process_frame
	
	# 8) Connect action notification signal to engine's function for re-emission
	new_notif.connect("action_triggered",_on_notification_action)
	
	# 9) Vertical absolute reflow for ALL items (including the new one)
	_reflow_bottom_to_top()
	
	# 10) Start the notification (in → wait → out → free)
	new_notif.start_notification()

# API for setting default payload
func set_default_payload(payload : Variant) -> void:
	# NOTE: I don't need to filter the payload variant because when i _init a Payload class with a parameter, it calls 
	#       NotificationEngine._extract_payload() which does all the heavy lifting by itself
	#       (+ removes both here and in Payload redundant code)
	
	# Create a Payload Resource with all the correct settings through its _init func
	var candidate : Payload = Payload.new(payload)
	# Try tyo save my Payload candidate inside the default path and store the operation result
	var result : Error = ResourceSaver.save(candidate,DEFAULT_PAYLOAD_PATH)
	# If the result is OK then continue, otherwise push an error and return early
	if result != OK:
		push_error("ResourceSaver couldn't save ",candidate," to ",DEFAULT_PAYLOAD_PATH)
		return
	DEFAULT_PAYLOAD = candidate

# API for clearing the default payload
func clear_default_payload() -> void:
	DEFAULT_PAYLOAD = null
	if FileAccess.file_exists(DEFAULT_PAYLOAD_PATH):
		if DirAccess.remove_absolute(DEFAULT_PAYLOAD_PATH) != OK:
			push_error("Unable to remove %s"%DEFAULT_PAYLOAD_PATH)

# API for setting the spacing (reflows automatically through spacing's setter
func set_spacing(new_spacing : float) -> void:
	spacing = new_spacing

# API for getting the spacing
func get_spacing() -> int:
	return spacing

# API for setting alignment (NOTE: notification alignment is applied only to the NEXT notifications)
func set_alignment(mode : SIDE) -> void:
	if mode is SIDE:
		LOCATION = mode

# API for getting alignment
func get_alignment() -> SIDE:
	return LOCATION
#endregion

# Extracts all payload parameters onto the target notification in a modular manner.
# NOTE: Remember! If the key is present but the value then set it anyway. If the key is not present, skip entirely.
func _extract_payload(payload : Variant, target : Variant) -> void:
	if !(target is Payload) and !(target is NotificationView):
		push_error("[NotificationEngine] | Invalid target for '_extract_payload': target of type %s and class %s was assigned!"%[type_string(typeof(target)),target.get_class()])
		return
	# NOTE: 
	#		The notification scene hides every customizable element until it is set through the setter of that specific parameter.
	#		Setting ANY parameter (other than the two durations) WILL make that element visible so don't do what i did for "title"
	#		unless you know what you're doing.
	#		(i'm watching you)
	if payload is Dictionary:
		
		# Set the title
		if payload.has("title"):
			var title_candidate = payload.get("title")
			if title_candidate is String:
				target.title_content = title_candidate
			elif title_candidate == null:
				target.title_candidate = ""
				if LOGGING:
					print("[NotificationEngine] | Title module: Title is empty.")
			else:
				push_warning("[NotificationEngine] | Title module: Invalid title module: Content is not string or null. Disregarding content.")
		else:
			if LOGGING:
				print("[NotificationEngine] | Title module: No title module present; skipping.")
		
		# Set the icon
		if payload.has("icon"):
			var icon_candidate = payload.get("icon")
			if icon_candidate is Texture2D:
				target.icon = icon_candidate
			elif icon_candidate == null:
				target.icon = null
				if LOGGING:
					print("[NotificationEngine] | Icon module: Icon is empty.")
			else:
				push_warning("[NotificationEngine] | Icon module: Invalid icon module, disregarding content.")
		else:
			if LOGGING:
				print("[NotificationEngine] | Icon module: No icon module present; skipping.")
		
		# Set the body
		if payload.has("body"):
			var body_candidate = payload.get("body")
			if body_candidate is String:
				target.body_content = body_candidate
			elif body_candidate == null:
				target.body_content = ""
				if LOGGING:
					print("[NotificationEngine] | Body module: Body is empty.")
			else:
				push_warning("[NotificationEngine] | Invalid body module: Content is not string. Disregarding content.")
		else:
			if LOGGING:
				print("[NotificationEngine] | Body module: No body module present; skipping.")
		
		# Set the actions
		if payload.has("actions"):
			var actions_candidate = payload.get("actions")
			if actions_candidate is Array and actions_candidate.size() > 0:
				target.actions = actions_candidate
			elif actions_candidate == null or (actions_candidate is Array and actions_candidate.size() == 0):
				target.actions = []
				if LOGGING:
					print("[NotificationEngine] | Actions module: Actions is empty.")
			else:
				push_warning("[NotificationEngine] | Invalid actions module, disregarding content.")
		else:
			if LOGGING:
				print("[NotificationEngine] | Actions module: No actions module present; skipping.")
		
		# Set the theme
		if payload.has("theme"):
			var theme_candidate = payload.get("theme")
			# Check wether the format is String
			if theme_candidate is String:
				# If it is, check if the wanted theme string is present in the presets
				if THEMES.has(theme_candidate):
					# If it is, apply the wanted theme to the target notification
					target.theme = THEMES[theme_candidate]
				else:
					push_warning("[NotificationEngine] | Theme module: Invalid built-in theme name, disregarding content.")
			# Check wether the format is Theme
			elif theme_candidate is Theme:
				# If so apply that theme directly to the target notification
				target.theme = theme_candidate
			elif theme_candidate == null:
				target.theme = null
				if LOGGING:
					print("[NotificationEngine] | Theme module: Theme is empty.")
			else:
				push_warning("[NotificationEngine] | Theme module: Invalid format for theme: %s, skipping module."%type_string(typeof(theme_candidate)))
		else:
			if LOGGING:
				print("[NotificationEngine] | Theme module: No theme module present; skipping.")
		
		# Set the sounds
		if payload.has("sounds"):
			var sounds_candidate = payload.get("sounds")
			if sounds_candidate is Dictionary:
				target.sounds = sounds_candidate
			elif sounds_candidate == null or (sounds_candidate is Dictionary and sounds_candidate.keys().size() == 0):
				target.sounds = {}
				if LOGGING:
					print("[NotificationEngine] | Sounds module: Sounds is empty.")
			else:
				push_warning("[NotificationEngine] | Sounds module: Invalid sounds module, disregarding content.")
		else:
			if LOGGING:
				print("[NotificationEngine] | Sounds module: No sounds module present; skipping.")
		
		# Set the duration
		if payload.has("duration"):
			var duration_candidate = payload.get("duration")
			target.duration_seconds = float(duration_candidate)
		else:
			if LOGGING:
				print("[NotificationEngine] | Duration module: No duration module present; skipping.")
		
		# Set the animations duration
		if payload.has("animation_duration"):
			var anim_dur_candidate = payload.get("animation_duration")
			target.animation_duration = float(anim_dur_candidate)
		else:
			if LOGGING:
				print("[NotificationEngine] | Animation duration module: No animation duration module present; skipping.")
	
	
	elif payload is Payload: # A Payload class is a complete snapshot of Payload so it only makes sense to add EVERY field 
		target.title_content = payload.title_content
		target.icon = payload.icon 
		target.body_content = payload.body_content 
		target.actions = payload.actions
		target.theme = payload.theme
		target.sounds = payload.sounds
		target.duration_seconds = payload.duration_seconds
		target.animation_duration = payload.animation_duration

# Frees the notification and reflows the others (bottom → top)
func _free_notification(notif : NotificationView) -> void:
	if not is_instance_valid(notif):
		return
	if root == null:
		return
	
	# Disconnect "action_triggered" from on_notification_action_pressed to avoid possible errors
	if notif.is_connected("action_triggered", _on_notification_action):
		notif.disconnect("action_triggered",_on_notification_action)
	
	# NOTE: This approach won't work to allow the sound to end
	#if notif._in_player.playing:
	#	await notif._in_player.finished
	#
	#if notif._out_player.call_deferred("get","playing"):
	#	await notif._out_player.finished
	#
	#if notif._close_player.playing:
	#	await notif._close_player.finished
	#
	#if notif._action_player.playing:
	#	await notif._action_player.finished
	
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
