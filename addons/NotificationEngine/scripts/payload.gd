# payload.gd
extends Resource
## A class used to store and re-use the same payload in a more stramlined way.
## Should be considered as a "full snapshot" of a payload. This has EVERYTHING.
class_name Payload
@export var      title_content : String = "" # Title text.
@export var               icon : Texture2D = null # Icon.
@export var       body_content : String = ""  # Body text.
@export var            actions : Array[Dictionary] = [] # Buttons.
@export var              theme : Theme = null
@export var   duration_seconds : float = 0.0 # Total duration (s).
@export var animation_duration : float = 0.0 # Animation duration (s).
@export var             sounds : Dictionary[String, AudioStream] = {}

func _init(initializer : Variant = null) -> void:
	if initializer != null:
		NotificationEngine._extract_payload(initializer,self)

## Returns a Dictionary formatted like a dictionary type payload.
func to_dict() -> Dictionary:
	# Create a candidate dict, empty by default, then fill it value by value
	var candidate_dict : Dictionary = {}
	
	# Add title
	if title_content != "" and title_content != null:
		candidate_dict["title"] = title_content
	
	# Add icon
	if icon != null:
		candidate_dict["icon"] = icon
	
	# Add body
	if body_content != "" and body_content != null:
		candidate_dict["body"] = body_content
	
	# Add actions
	if actions != null && actions.size() > 0:
		# Create candidate actions
		var candidate_actions : Array[Dictionary] = []
		# Then cycle through every action
		for action in actions:
			# Validate the action (if it's not in the dict it will return null which is obviously not String)
			if action.get("id") is String and action.get("label") is String:
				# And finally add the action to the candidate actions ONLY if it's validated 
				# (don't check for icon because it will gett added if present)
				candidate_actions.append(action)
		# Then after building the validated actions array add it to the payload dict
		candidate_dict["actions"] = candidate_actions
	
	# Add theme
	if theme != null:
		candidate_dict["theme"] = theme
	
	if sounds != null:
		candidate_dict["sounds"] = sounds
	
	# Add duration
	if duration_seconds > 0.0:
		candidate_dict["duration"] = duration_seconds
	
	# Add animation duration
	if animation_duration > 0.0:
		candidate_dict["animation_duration"] = animation_duration
	
	# After building it return. If every parameter is either null, zero or empty then it will return "{}"
	return candidate_dict
