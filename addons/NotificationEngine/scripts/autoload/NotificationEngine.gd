# NotificationEngine.gd
extends Node

#region SIGNALS
@warning_ignore("unused_signal")
signal notif_popup(duration_s : float) # NOTE: Might want to add more variables to the signal later
@warning_ignore("unused_signal")
signal notif_popout
signal notification_action(notification: Control, notif_id : int, action_id : String)
#endregion

#region INTERNALS
enum SIDE {BOTTOM_RIGHT,BOTTOM_LEFT}
var LOCATION : SIDE = SIDE.BOTTOM_RIGHT
const NOTIFICATION : PackedScene = preload("res://addons/NotificationEngine/scenes/notification.tscn")
const CHECK_INTERVAL : float = 0.5
var CURRENT_TIME : float = 0.0
#endregion

#region UTILITIES
var root : CanvasLayer # TODO: Turn root into an always-on-top, transparent, borderless window 
					   # 	   so notifications can be seen outside of the main window
var spacing : int = 5
#endregion

func _ready() -> void:
	get_window().size_changed.connect(_on_window_size_changed)
	# Prepare the global overlay where notifications live across scene changes
	root = CanvasLayer.new()
	root.name = "NotificationsRoot"
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

# API Endpoint for notification calls
func notify(payload : Dictionary) -> void:
	# 1) Create the new notification node
	var new_notif : Control = NOTIFICATION.instantiate()
	
	# 2) Makes notification transparent to prevent it showing for a split second
	new_notif.modulate = Color(1,1,1,0)
	
	# 3) Add to overlay first so size/layout become valid
	root.add_child(new_notif)
	
	# 4) Wait 1 frame so size.x/size.y are correct before positioning/tweening
	await get_tree().process_frame
	
	# 5) Unpack payload
	#region PAYLOAD unpacking
	
	# NOTE: 
	#		The notification scene hides every customizable element until it is set through the setter.
	#		Setting ANY parameter (other than the two durations) WILL make that element visible so don't do what i did for "title"
	#		unless you know what you're doing.
	#		(i'm watching you)
	
	# NOTE 2:
	#		I COULD use a match payload.keys(): statement but i won't for now
	
	# Set the title
	if payload.has("title") and payload.get("title") is String:
		new_notif.title_content = payload["title"]
	else:
		new_notif.title_content = "No title"
	# Set the icon
	if payload.has("icon") and payload.get("icon") is Texture2D:
		new_notif.icon = payload["icon"]
	# Set the body
	if payload.has("body") and payload.get("body") is String:
		new_notif.body_content = payload["body"]
	# Set the actions
	if payload.has("actions") and payload.get("actions") is Array:
		new_notif.actions = payload["actions"]
	# Set the duration
	if payload.has("duration") and (payload.get("duration") is float or payload.get("duration") is int):
		new_notif.duration_seconds = payload["duration"]
	# Set the animations duration
	if payload.has("animation_duration") and (payload.get("animation_duration") is float or payload.get("animation_duration") is int):
		new_notif.animation_duration = payload["animation_duration"]
	
	#endregion
	
	# 6) Wait for containers to change size
	await get_tree().process_frame
	
	# 7) Connect notification signal to engine's function
	new_notif.connect("action_triggered",_on_notification_action)
	
	# 8) Absolute reflow for ALL items (including the new one)
	_reflow_bottom_to_top()
	
	# 9) Start the show (in → wait → out → free)
	new_notif.start_notification()

func set_alignment(mode : SIDE) -> void:
	if mode is SIDE:
		LOCATION = mode

func get_alignment() -> SIDE:
	return LOCATION

# Frees the notification and reflows the others (bottom → top)
func free_notification(notif : Node) -> void:
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
	
	var win_h         : float = get_window().get_visible_rect().size.y
	var gap           : float = spacing
	var bottom_margin : float = spacing   # keep a consistent "breathing" space at the bottom
	
	var accum : float = 0.0
	var anim_dur : float = 0.3  # single, consistent reflow duration
	
	for notif in items:
		var h : float = notif.size.y
		# bottom-attached layout with bottom margin considered
		var target_y : float = win_h - bottom_margin - accum - h
		
		var t : Tween = get_tree().create_tween()
		t.set_trans(Tween.TRANS_QUAD)
		t.set_ease(Tween.EASE_OUT)
		t.tween_property(notif, "position:y", target_y, anim_dur)
		
		accum += h + gap

func _on_window_size_changed() -> void:
	_reflow_bottom_to_top()

func _on_notification_action(notification : Control, notif_id : int, action_id : String):
	self.emit_signal("notification_action",notification,notif_id,action_id)
