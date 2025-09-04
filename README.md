# NotificationEngine

A lightweight and flexible notification system for Godot 4.x.  
Shows customizable popup notifications (title, body, icon, actions) with smooth animations, stacking, themes, and signals you can listen to from anywhere. Includes a demo scene to learn how to build payloads interactively.

---

## ✨ Features
- Global notification engine (autoload singleton).
- Bottom-left / bottom-right alignment presets.
- Title, body, optional icon.
- Action buttons (with `id`, `label`, optional `icon`).
- Signals for popup, popout, and action clicks.
- Theming support:
  - Built-in `"default"` theme.
  - Pass your own `Theme` resource directly.
- Safe defaults and payload validation.
- Works out-of-the-box, no scene editing required.
- Demo scene included to test payloads and learn usage.

---

## 📦 Installation
1. Copy the `addons/NotificationEngine/` folder into your Godot project.
2. Enable the plugin:
   - In the editor: **Project → Project Settings → Plugins** → enable **NotificationEngine**.
   - This will autoload the singleton `NotificationEngine`.

---

## ⚙️ Setup
- The engine automatically creates a `CanvasLayer` root called `NotificationsRoot`.
- Notifications are instantiated inside this layer and survive scene changes.
- You can trigger notifications from anywhere by calling `NotificationEngine.notify()` with a payload dictionary.
- You can get/set `NotificationEngine`'s settings like spacing and alignment through the built-in methods: `set_spacing()`,`set_alignment()` and `get_alignment()`

---

## 📝 Example

```gdscript
var example_icon := preload("res://icon.svg")

NotificationEngine.notify({
	"title": "Hello!",                       # NOT REQUIRED BUT RECOMMENDED
	"body": "This is a test notification.",  # OPTIONAL
	"icon": example_icon,                    # OPTIONAL
	"actions": [                             # OPTIONAL
		{
			"id": "action_1",                # REQUIRED for actions
			"label": "Action 1",             # REQUIRED for actions
			"icon": example_icon             # OPTIONAL for actions
		},
		{
			"id": "action_2",
			"label": "Action 2"
		}
	],
	"theme": "default",                      # OPTIONAL (string for built-in, or a Theme resource)
	"duration": 5.5,                         # OPTIONAL (seconds, default 3.0)
	"animation_duration": 0.4                # OPTIONAL (seconds, default 0.3)
})
```
## 🎮 Demo Scene
The repository includes a demo scene that lets you try out notifications interactively:
- Fill in title, body, actions, theme, etc.
- Press Submit to spawn a live notification.
- Great for documentation and for learning how to structure payloads.

---

## 🔔 Signals
The engine emits the following signals:
- `notif_popup(notification : Control)`
- `notif_popout(notification : Control)`
- `notification_action(notification : Control, notif_id : int, action_id : String)`
You can connect to them from anywhere to handle notification lifecycle and actions.

---

## 📜 License
MIT License. Free to use, modify and share.
