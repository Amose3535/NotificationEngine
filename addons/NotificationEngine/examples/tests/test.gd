extends Control

const ICON = preload("res://icon.svg")
const THEME = preload("res://addons/NotificationEngine/resources/themes/default.tres")
@onready var title: LineEdit = $PanelContainer/MarginContainer/VBoxContainer/TitleContainer/title
@onready var body: TextEdit = $PanelContainer/MarginContainer/VBoxContainer/BodyContainer/body
@onready var icon: OptionButton = $PanelContainer/MarginContainer/VBoxContainer/IconContainer/icon
@onready var actions: TextEdit = $PanelContainer/MarginContainer/VBoxContainer/ActionsContainer/actions
@onready var theme_opt: OptionButton = $PanelContainer/MarginContainer/VBoxContainer/ThemeContainer/VBoxContainer/theme_opt
@onready var theme_custom: LineEdit = $PanelContainer/MarginContainer/VBoxContainer/ThemeContainer/VBoxContainer/theme_custom
@onready var duration: LineEdit = $PanelContainer/MarginContainer/VBoxContainer/DurationContainer/duration
@onready var animation_duration: LineEdit = $PanelContainer/MarginContainer/VBoxContainer/AnimationDurationContainer/animation_duration
@onready var alignment: OptionButton = $PanelContainer/MarginContainer/VBoxContainer/AlignContainer/alignment


#region INTERNAL VARIABLES
var _title : String = ""
var _body : String = ""
var _icon : Texture2D = null
var _actions : Array[Dictionary] = []
var _theme : Theme = null
var _theme_path : String = ""
var _duration : float = 0.0
var _anim_duration : float = 0.0

func _ready() -> void:
	NotificationEngine.connect("notification_action",_on_notification_action)
	_on_title_text_changed(title.text)
	_on_body_text_changed()
	_on_icon_item_selected(icon.selected)
	_on_actions_text_changed()
	_on_theme_opt_item_selected(theme_opt.selected)
	_on_theme_custom_text_changed(theme_custom.text)
	_on_duration_text_changed(duration.text)
	_on_animation_duration_text_changed(animation_duration.text)
	_on_alignment_item_selected(alignment.selected)


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
	if dur_candidate != 0.0:
		_duration = dur_candidate

func _on_animation_duration_text_changed(new_text: String) -> void:
	var anim_dur_candidate := float(new_text)
	if anim_dur_candidate != 0.0:
		_anim_duration = anim_dur_candidate

func _on_alignment_item_selected(index: int) -> void:
	match index:
		0: # Bottom-right
			NotificationEngine.set_alignment(NotificationEngine.SIDE.BOTTOM_RIGHT)
		
		1: # Bottom-left
			NotificationEngine.set_alignment(NotificationEngine.SIDE.BOTTOM_LEFT)

func _on_submit_pressed() -> void:
	var payload : Dictionary = {}
	if _title != "":          payload["title"] = _title
	if _body != "":           payload["body"] = _body
	if _icon != null:         payload["icon"] = _icon
	if _actions.size() > 0:   payload["actions"] = _actions
	if _theme != null:        payload["theme"] = _theme
	if _duration > 0.0:       payload["duration"] = _duration
	if _anim_duration > 0.0:  payload["animation_duration"] = _anim_duration

	NotificationEngine.notify(payload)


func _on_notification_action(notification_node : Control, notif_id : int, action_id : String) -> void:
	match action_id:
		"action_1":
			NotificationEngine.set_alignment(NotificationEngine.SIDE.BOTTOM_LEFT)
		"action_2":
			NotificationEngine.set_alignment(NotificationEngine.SIDE.BOTTOM_RIGHT)
