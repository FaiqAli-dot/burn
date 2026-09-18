class_name UIManager
extends CanvasLayer
## Minimal HUD: level label, burn %, retry, continue, win/fail banners.

signal retry_pressed
signal continue_pressed

@onready var level_label: Label = $Root/TopBar/LevelLabel
@onready var percent_label: Label = $Root/TopBar/PercentLabel
@onready var retry_button: Button = $Root/RetryButton
@onready var continue_button: Button = $Root/ContinueButton
@onready var banner: Label = $Root/Banner
@onready var subtitle: Label = $Root/Subtitle


func _ready() -> void:
	retry_button.pressed.connect(func() -> void: retry_pressed.emit())
	if continue_button:
		continue_button.pressed.connect(func() -> void: continue_pressed.emit())
		continue_button.visible = false
	banner.visible = false
	subtitle.visible = false
	_style_retry()


func set_level_name(text: String) -> void:
	level_label.text = text.to_upper()


func set_percent(percent: float) -> void:
	percent_label.text = "%d%%" % int(round(percent))


func show_playing() -> void:
	banner.visible = false
	subtitle.visible = false
	retry_button.text = "RETRY"
	retry_button.modulate.a = 0.55
	if continue_button:
		continue_button.visible = false


func show_won() -> void:
	banner.text = "BURNED"
	banner.visible = true
	subtitle.text = "100%"
	subtitle.visible = true
	retry_button.modulate.a = 1.0
	if continue_button:
		continue_button.visible = true
		continue_button.text = "CONTINUE"
	_pulse_banner()


func show_failed(percent: float) -> void:
	banner.text = "STALLED"
	banner.visible = true
	subtitle.text = "%d%% — try another spark" % int(round(percent))
	subtitle.visible = true
	retry_button.modulate.a = 1.0
	if continue_button:
		continue_button.visible = false
	_pulse_banner()


func _pulse_banner() -> void:
	banner.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(banner, "modulate:a", 1.0, 0.25)


func _style_retry() -> void:
	retry_button.add_theme_font_size_override("font_size", 18)
	retry_button.focus_mode = Control.FOCUS_NONE
	if continue_button:
		continue_button.add_theme_font_size_override("font_size", 20)
		continue_button.focus_mode = Control.FOCUS_NONE
