@tool
extends EditorPlugin

# Function called when the plugin is ->ACTIVATED<-
func _enter_tree() -> void:
	# Initialization of the plugin goes here.
	self.add_autoload_singleton("NotificationEngine","res://addons/NotificationEngine/scripts/autoload/NotificationEngine.gd")


# Function called when the plugin is ->DISACTIVATED<-
func _exit_tree() -> void:
	# Clean-up of the plugin goes here.
	self.remove_autoload_singleton("NotificationEngine")
