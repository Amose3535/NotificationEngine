# NotificationEngine

A lightweight and flexible notification system for Godot 4.x.  
Shows customizable popup notifications (title, body, icon, actions, sounds) with smooth animations, stacking, themes, and signals you can listen to from anywhere. Includes a demo scene to learn how to build payloads interactively.

---

## ✨ Features
- Global notification engine (autoload singleton) to access all its features.
- Bottom-left / bottom-right alignment presets for notifications.
- Feature-packed notifications: title, body, icon, actions, sounds, themes, duration.
- Action buttons (with `id`, `label`, optional `icon`, and optional `dismiss`).
- Signals for popup, popout, and action clicks.
- Sounds support:
  - `in`, `out`, `action`, `close` channels.
  - Configurable per payload, fallback to global defaults.
  - **Note**: sounds must be shorter than `animation_duration` (for `out/close`) or `duration+animation_duration` (for `in`) to avoid being cut off.
- Theming support:
  - Built-in `"default"` theme.
  - Pass your own `Theme` resource directly.
- Safe defaults and strong payload validation.
- Works out-of-the-box, no scene editing required and easy to pick up.
- Demo scene included to test payloads and learn usage.
- Support for sticky and instant notifications:
  - Sticky: `duration <= 0` (notification stays until dismissed).
  - Instant: `animation_duration <= 0` (appears and disappears instantly).

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
- You can trigger notifications from anywhere by calling `NotificationEngine.notify()` with a payload dictionary **or a `Payload` Resource**.
- You can set a default payload on disk (`DEFAULT_PAYLOAD.tres`) or clear it with `clear_default_payload()`.
- You can get/set `NotificationEngine`'s settings like spacing and alignment through built-in methods:  
  `set_spacing(new_spacing : float)`, `set_alignment(mode : SIDE)`, `get_alignment()`
- You can access the following signals for full control:  
  `notif_popup(notification : Control)`, `notif_popout(notification : Control)`, and  
  `notification_action(notification: Control, notif_id : int, action_id : String)`

---

## 📝 Example

```gdscript
var example_icon := preload("res://icon.svg")
var example_sound := preload("res://ding.ogg")

NotificationEngine.notify({
	"title": "Hello!",                       # NOT REQUIRED BUT RECOMMENDED
	"body": "This is a test notification.",  # OPTIONAL
	"icon": example_icon,                    # OPTIONAL
	"actions": [                             # OPTIONAL
		{
			"id": "action_1",                # REQUIRED for actions
			"label": "Action 1",             # REQUIRED for actions
			"dismiss": true                  # OPTIONAL (defaults to false)
		}
	],
	"theme": "default",                      # OPTIONAL (string for built-in, or a Theme resource)
	"duration": 0,                           # OPTIONAL: sticky (0 = stays until dismissed)
	"animation_duration": 0.0,               # OPTIONAL: instant (0 = instant show/hide)
	"sounds": {                              # OPTIONAL
		"in": example_sound,
		"out": example_sound,
		"action": example_sound,
		"close": example_sound
	}
})
```

---

## 🎮 Demo Scene
The repository includes a demo scene that lets you try out notifications interactively:
- Fill in title, body, actions, theme, sounds, etc.
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

---

# 🆕 Changelog from v1.0.1
- Added **Payload Resource** support (`.tres`) as reusable snapshots.  
- Added **default payload** save/load/clear support.  
- Added **sticky notifications** (`duration <= 0`).  
- Added **instant notifications** (`animation_duration <= 0`).  
- Added **sounds module** (`in`, `out`, `action`, `close`) with payload and global fallback.  
- Added `dismiss` option for action buttons and a close “X” button.  
- Improved validation, logging, and demo scene with interactive payload building.  
