# NotificationEngine

A lightweight and flexible notification system for Godot 4.x.  
Shows customizable popup notifications (title, body, icon, actions) with smooth animations, stacking, and signals you can listen to from anywhere.

---

## ✨ Features
- Global notification engine (autoload singleton).
- Bottom-left / bottom-right alignment presets.
- Title, body, optional icon, action buttons.
- Signals for popup, popout, and action clicks.
- Safe defaults and payload validation.
- Works out-of-the-box, no scene editing required.

- (FUTURE UPDATE) Theming support (apply a custom `Theme`).

---

## 📦 Installation
1. Copy the `addons/NotificationEngine/` folder into your Godot project.
2. Enable the plugin:
   - In the editor: **Project → Project Settings → Plugins** → enable **NotificationEngine**.
   - This will autoload the singleton `NotificationEngine`.
3. (Optional) Adjust default settings in `NotificationEngine.gd` (spacing, hpad, alignment).

---

## ⚙️ Setup
- The engine automatically creates a `CanvasLayer` root called `NotificationsRoot`.
- Notifications are instantiated inside this layer and survive scene changes.
- You can trigger notifications from anywhere by calling NotificationEngine.notify() like this:

```gdscript
var example_icon := preload(...)

NotificationEngine.notify({
	"title": "Hello!",						# NOT REQUIRED BUT HIGHLY SUGGESTED
	"body": "This is a test notification.",	# OPTIONAL
	"icon": example_icon,					# OPTIONAL
	"actions":[{ # OPTIONAL
		"id":"action_1", 	# REQUIRED FOR ACTIONS
		"label":"Action 1", # REQUIRED FOR ACTIONS
		"icon":example_icon # OPTIONAL FOR ACTIONS
		},
		{...} 				# OTHER ACTIONS (OPTIONAL)
	],
	"duration":5.5,							# OPTIONAL
	"animation_duration":0.4				# OPTIONAL
})
```

