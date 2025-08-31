# NotificationEngine.gd
extends Node

#region SIGNALS
@warning_ignore("unused_signal")
signal notif_popup(duration_s : float) # NOTE: Might want to add more variables to the signal later
@warning_ignore("unused_signal")
signal notif_popout
#endregion

#region INTERNALS
const NOTIFICATION : PackedScene = preload("res://main/scenes/notification.tscn")
const CHECK_INTERVAL : float = 0.5
var CURRENT_TIME : float = 0.0
#endregion

#region UTILITIES
var root : CanvasLayer
var spacing : int = 5
#endregion

func _ready() -> void:
	# Prepare the global overlay where notifications live across scene changes
	root = CanvasLayer.new()
	root.name = "NotificationsRoot"
	if not get_tree().root.has_node("NotificationsRoot"):
		get_tree().root.add_child.call_deferred(root)
	else:
		print("NotificationsRoot not instantiated: node already exists.")
		root = get_tree().root.get_node("NotificationsRoot")
	
	#region TEST
	####################################  TEST  ####################################
	# var notif_instance : Node = NOTIFICATION.instantiate()
	# root.add_child(notif_instance)
	################################################################################
	#endregion

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
		
		if total_y + (notification_number - 1) * spacing > get_viewport().get_visible_rect().size.y:
			push_warning("VISIBILITY WARNING: The notification stack exceeds viewport height.")

func notify(payload : Dictionary) -> void:
	# 1) Create the new notification node
	var new_notif : Node = NOTIFICATION.instantiate()
	
	# 2) Makes notification transparent to prevent it showing for a split second
	new_notif.modulate = Color(1,1,1,0)
	
	# 3) Add to overlay first so size/layout become valid
	root.add_child(new_notif)
	
	# 4) Wait 1 frame so size.x/size.y are correct before positioning/tweening
	await get_tree().process_frame
	
	# 5) Unpack payload (defensive defaults)
	#region PAYLOAD unpacking
	if payload.has("title"):
		new_notif.title_content = payload["title"]
	else:
		new_notif.title_content = "NONE"
	
	if payload.has("body"):
		new_notif.body_content = payload["body"]
	else:
		new_notif.body_content = ""
	
	if payload.has("animation_duration"):
		new_notif.animation_duration = payload["animation_duration"]
	
	if payload.has("duration"):
		new_notif.duration_seconds = payload["duration"]
	#endregion
	
	# 6) Wait for containers to change size
	await get_tree().process_frame
	
	# 7) Absolute reflow for ALL items (including the new one)
	_reflow_bottom_to_top()
	
	# 8) Start the show (in → wait → out → free)
	new_notif.start_notification()
	

# Frees the notification and reflows the others (bottom → top)
func free_notification(notif : Node) -> void:
	if not is_instance_valid(notif):
		return
	if root == null:
		return
	
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
