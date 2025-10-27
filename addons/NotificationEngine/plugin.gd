@tool
extends EditorPlugin



func _enable_plugin() -> void:
	self.add_autoload_singleton("NotificationEngine","res://addons/NotificationEngine/scripts/autoload/NotificationEngine.gd")


func _disable_plugin() -> void:
	self.remove_autoload_singleton("NotificationEngine")


func _enter_tree() -> void:
	# Initialization of the plugin goes here.
	pass

func _exit_tree() -> void:
	# Clean-up of the plugin goes here.
	pass
