extends Control

const ICON = preload("res://icon.svg")
const THEME = preload("res://addons/NotificationEngine/resources/themes/default.tres")
@onready var title: LineEdit = $PanelContainer/MarginContainer/VBoxContainer/VFlowContainer/TitleContainer/title
@onready var body: TextEdit = $PanelContainer/MarginContainer/VBoxContainer/VFlowContainer/BodyContainer/body
@onready var icon: OptionButton = $PanelContainer/MarginContainer/VBoxContainer/VFlowContainer/IconContainer/icon
@onready var actions: TextEdit = $PanelContainer/MarginContainer/VBoxContainer/VFlowContainer/ActionsContainer/actions
@onready var theme_opt: OptionButton = $PanelContainer/MarginContainer/VBoxContainer/VFlowContainer/ThemeContainer/VBoxContainer/theme_opt
@onready var theme_custom: LineEdit = $PanelContainer/MarginContainer/VBoxContainer/VFlowContainer/ThemeContainer/VBoxContainer/theme_custom
@onready var sound_in: LineEdit = $PanelContainer/MarginContainer/VBoxContainer/VFlowContainer/SoundsContainer/VBoxContainer/in
@onready var sound_out: LineEdit = $PanelContainer/MarginContainer/VBoxContainer/VFlowContainer/SoundsContainer/VBoxContainer/out
@onready var sound_close: LineEdit = $PanelContainer/MarginContainer/VBoxContainer/VFlowContainer/SoundsContainer/VBoxContainer/close
@onready var sound_action: LineEdit = $PanelContainer/MarginContainer/VBoxContainer/VFlowContainer/SoundsContainer/VBoxContainer/action
@onready var duration: LineEdit = $PanelContainer/MarginContainer/VBoxContainer/VFlowContainer/DurationContainer/duration
@onready var animation_duration: LineEdit = $PanelContainer/MarginContainer/VBoxContainer/VFlowContainer/AnimationDurationContainer/animation_duration
@onready var alignment: OptionButton = $PanelContainer/MarginContainer/VBoxContainer/VFlowContainer/AlignContainer/alignment


#region INTERNAL VARIABLES
var _title : String = ""; var _title_enabled : bool = true
var _body : String = ""; var _body_enabled : bool = true
var _icon : Texture2D = null; var _icon_enabled : bool = true
var _actions : Array[Dictionary] = []; var _actions_enabled : bool = true
var _theme : Theme = null; var _theme_enabled : bool = true
var _theme_path : String = ""
var _duration : float = 0.0; var _duration_enabled : bool = true
var _anim_duration : float = 0.0; var _anim_duration_enabled : bool = true
var _sounds : Dictionary[String, AudioStream] = {}; var _sounds_enabled : bool = true
#endregion

func _ready() -> void:
	# Connects NotificationEngine's notification_action signal to our custom _on_notification_action function 
	# that prints all the necessary information
	NotificationEngine.connect("notification_action",_on_notification_action)
	# Initialize every field in this demo scene
	initialize_everything()

func initialize_everything() -> void:
	_on_title_text_changed(title.text)
	_on_body_text_changed()
	_on_icon_item_selected(icon.selected)
	_on_actions_text_changed()
	_on_theme_opt_item_selected(theme_opt.selected)
	_on_theme_custom_text_changed(theme_custom.text)
	_on_duration_text_changed(duration.text)
	_on_animation_duration_text_changed(animation_duration.text)
	_on_alignment_item_selected(alignment.selected)
	_on_in_text_changed(sound_in.text)
	_on_out_text_changed(sound_out.text)
	_on_close_text_changed(sound_close.text)
	_on_action_text_changed(sound_action.text)

func _on_title_text_changed(new_text: String) -> void:
	_title = new_text

func _on_body_text_changed() -> void:
	_body = body.text

func _on_icon_item_selected(index: int) -> void:
	match index:
		0:
			_icon = null
		1:
			_icon = ICON

func _on_actions_text_changed() -> void:
	var txt := actions.text.strip_edges()
	if txt == "":
		_actions = []
		return
	
	var v = str_to_var(txt)
	if not (v is Array):
		_actions = []
		return
	
	# valida elementi
	var tmp : Array[Dictionary] = []
	for e in v:
		if e is Dictionary and e.has("id") and e.has("label") and e["id"] is String and e["label"] is String:
			tmp.append(e)
		else:
			_actions = []
			return
	
	_actions = tmp

func _on_theme_opt_item_selected(index: int) -> void:
	match index:
		0: # No theme (GD default)
			_theme = null
			theme_custom.text = ""
		
		1: # Default theme
			_theme = THEME
			theme_custom.text = THEME.resource_path
		
		2: # Custom theme
			if !FileAccess.file_exists(_theme_path): # check if file path is valid
				return
			var theme_candidate := load(_theme_path)
			if !(theme_candidate is Theme): # check if the candidate is actually a theme
				_theme = null
				return
			_theme = theme_candidate

func _on_theme_custom_text_changed(new_text: String) -> void:
	_theme_path = new_text

func _on_duration_text_changed(new_text: String) -> void:
	var dur_candidate := float(new_text)
	_duration = dur_candidate

func _on_animation_duration_text_changed(new_text: String) -> void:
	var anim_dur_candidate := float(new_text)
	_anim_duration = anim_dur_candidate

func _on_alignment_item_selected(index: int) -> void:
	match index:
		0: # Bottom-right
			NotificationEngine.set_alignment(NotificationEngine.SIDE.BOTTOM_RIGHT)
		
		1: # Bottom-left
			NotificationEngine.set_alignment(NotificationEngine.SIDE.BOTTOM_LEFT)

func _on_in_text_changed(new_text: String) -> void:
	_sounds["in"] = null
	if FileAccess.file_exists(new_text):
		var sound_candidate = load(new_text)
		if sound_candidate is AudioStream:
			_sounds["in"] = sound_candidate
	else:
		print("Warning! No file %s"%new_text)

func _on_out_text_changed(new_text: String) -> void:
	_sounds["out"] = null
	if FileAccess.file_exists(new_text):
		var sound_candidate = load(new_text)
		if sound_candidate is AudioStream:
			_sounds["out"] = sound_candidate
	else:
		print("Warning! No file %s"%new_text)

func _on_close_text_changed(new_text: String) -> void:
	_sounds["close"] = null
	if FileAccess.file_exists(new_text):
		var sound_candidate = load(new_text)
		if sound_candidate is AudioStream:
			_sounds["close"] = sound_candidate
	else:
		print("Warning! No file %s"%new_text)

func _on_action_text_changed(new_text: String) -> void:
	_sounds["action"] = null
	if FileAccess.file_exists(new_text):
		var sound_candidate = load(new_text)
		if sound_candidate is AudioStream:
			_sounds["action"] = sound_candidate
	else:
		print("Warning! No file %s"%new_text)

func _on_title_enabled_toggled(toggled_on: bool) -> void:
	_title_enabled = toggled_on

func _on_body_enabled_toggled(toggled_on: bool) -> void:
	_body_enabled = toggled_on

func _on_icon_enabled_toggled(toggled_on: bool) -> void:
	_icon_enabled = toggled_on

func _on_actions_enabled_toggled(toggled_on: bool) -> void:
	_actions_enabled = toggled_on

func _on_theme_enabled_toggled(toggled_on: bool) -> void:
	_theme_enabled = toggled_on

func _on_duration_enabled_toggled(toggled_on: bool) -> void:
	_duration_enabled = toggled_on

func _on_animation_duration_enabled_toggled(toggled_on: bool) -> void:
	_anim_duration_enabled = toggled_on

func _on_sounds_enabled_toggled(toggled_on: bool) -> void:
	_sounds_enabled = toggled_on




func _on_submit_pressed() -> void:
	var payload : Dictionary = {}
	if _title_enabled:         payload["title"] = _title
	if _body_enabled:          payload["body"] = _body
	if _icon_enabled:          payload["icon"] = _icon
	if _actions_enabled:       payload["actions"] = _actions
	if _theme_enabled:         payload["theme"] = _theme
	if _actions_enabled:       payload["sounds"] = _sounds
	if _duration_enabled:      payload["duration"] = _duration
	if _anim_duration_enabled: payload["animation_duration"] = _anim_duration
	
	NotificationEngine.notify(payload)
	
	#print(payload["sounds"]) # OK


func _on_default_pressed() -> void:
	var payload : Dictionary = {}
	if _title_enabled:         payload["title"] = _title
	if _body_enabled:          payload["body"] = _body
	if _icon_enabled:          payload["icon"] = _icon
	if _actions_enabled:       payload["actions"] = _actions
	if _theme_enabled:         payload["theme"] = _theme
	if _duration_enabled:      payload["duration"] = _duration
	if _anim_duration_enabled: payload["animation_duration"] = _anim_duration
	
	NotificationEngine.set_default_payload(payload)


func _on_clear_pressed() -> void:
	NotificationEngine.clear_default_payload()


func _on_notification_action(notification_node : Control, notif_id : int, action_id : String) -> void:
	print("Notification: ",notification_node," Notification ID: ",notif_id," Action ID: ",action_id)
