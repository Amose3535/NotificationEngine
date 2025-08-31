extends Control

@onready var qr_bg: PanelContainer = $MarginContainer/UI/QR
@onready var qr_code: QRCodeRect = $MarginContainer/UI/QR/Margins/QRCodeRect
@onready var color_picker_button: ColorPickerButton = $MarginContainer/UI/Footer/MarginContainer/Control/ColorPickerButton
@onready var input: LineEdit = $MarginContainer/UI/Footer/MarginContainer/Control/Input
@onready var download_button: Button = $MarginContainer/UI/Footer/MarginContainer/Control/DownloadButton

const QRCode = preload("res://addons/qr_code/qr_code.gd")


func _on_input_text_changed(new_text: String) -> void:
	# NOTE: NUMERIC = 1, ALPHANUMERIC = 2, BYTE = 4, KANJI = 8
	new_text = UT.sanitize_string(new_text) # Cleans the string of any oddities before applying it to the QR code
	
	qr_code.mode = QRCode.Mode.BYTE
	
	# To prevent potential crashes due to an incorrect formatting in the same frame calls _apply_qr_data with the correct payload to 
	# be applied in the next frame
	call_deferred("_apply_qr_data", new_text)

func _apply_qr_data(p: String) -> void:
	# Prevents potential crashes upon empty string since certain encoders despise ""
	qr_code.data = p if p.length() > 0 else " "


func _on_color_picker_button_color_changed(color: Color) -> void:
	# Change the color of the background of the QR code to the according provided color
	
	# Get the BG Panel StyleBox and edit its color
	var bg_style_box : StyleBoxFlat = qr_bg.get_theme_stylebox("panel")
	bg_style_box.bg_color = color
	
	# Apply the edited BG Panel StyleBox to qr_bg
	qr_bg.add_theme_stylebox_override("panel",bg_style_box)
	
	# Also edit the qr code texture bg to conform to "color" color
	qr_code.light_module_color = color
	
	# For better visibility, the "on" pixels of the QR code should change hue depending on the BG
	var luminosity_growth_rate : float = 10.0
	var luminosity : float = pow(pow(color.r,luminosity_growth_rate)+pow(color.g,luminosity_growth_rate)+pow(color.b,luminosity_growth_rate),1.0/luminosity_growth_rate)
	qr_code.dark_module_color = Color(1-luminosity,1-luminosity,1-luminosity)
	
	


func _on_button_pressed() -> void:
	var QR_image : Image = qr_code.texture.get_image()
	if QR_image != null:
		QR_image.save_png("user://saved.png")
		var payload : Dictionary = {"title":"🔳 QR code saved 🔳", "body":"QR code has been saved!","duration":5.0,"animation_duration":0.3}
		NotificationEngine.notify(payload)
