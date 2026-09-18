class_name UIManager
extends CanvasLayer
## Premium minimal HUD: level, %, retry, continue, home, win/fail.

signal retry_pressed
signal continue_pressed
signal home_pressed

@onready var level_label: Label = $Root/TopBar/LevelLabel
@onready var percent_label: Label = $Root/TopBar/PercentLabel
@onready var home_button: Button = $Root/TopBar/HomeButton
@onready var retry_button: Button = $Root/RetryButton
@onready var continue_button: Button = $Root/ContinueButton
@onready var banner: Label = $Root/Banner
@onready var subtitle: Label = $Root/Subtitle
@onready var veil: ColorRect = $Root/Veil


func _ready() -> void:
	retry_button.pressed.connect(func() -> void: retry_pressed.emit())
	if continue_button:
		continue_button.pressed.connect(func() -> void: continue_pressed.emit())
		continue_button.visible = false
	if home_button:
		home_button.pressed.connect(func() -> void: home_pressed.emit())
		home_button.focus_mode = Control.FOCUS_NONE
		home_button.flat = true
	banner.visible = false
	subtitle.visible = false
	if veil:
		veil.visible = false
		veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_style_retry()


func set_level_name(text: String) -> void:
	level_label.text = text.to_upper()


func set_percent(percent: float) -> void:
	percent_label.text = "%d%%" % int(round(percent))


func show_playing() -> void:
	banner.visible = false
	subtitle.visible = false
	if veil:
		veil.visible = false
	retry_button.text = "RETRY"
	retry_button.modulate.a = 0.45
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
	_show_veil(0.22)
	_pulse_banner()


func show_failed(percent: float) -> void:
	banner.text = "STALLED"
	banner.visible = true
	subtitle.text = "%d%% — try another spark" % int(round(percent))
	subtitle.visible = true
	retry_button.modulate.a = 1.0
	if continue_button:
		continue_button.visible = false
	_show_veil(0.28)
	_pulse_banner()


func _show_veil(alpha: float) -> void:
	if veil == null:
		return
	veil.visible = true
	veil.color = Color(0.04, 0.03, 0.025, 0.0)
	var tw := create_tween()
	tw.tween_property(veil, "color:a", alpha, 0.3)


func _pulse_banner() -> void:
	banner.modulate.a = 0.0
	banner.scale = Vector2(0.96, 0.96)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(banner, "modulate:a", 1.0, 0.28)
	tw.tween_property(banner, "scale", Vector2.ONE, 0.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _style_retry() -> void:
	retry_button.add_theme_font_size_override("font_size", 18)
	retry_button.focus_mode = Control.FOCUS_NONE
	if continue_button:
		continue_button.add_theme_font_size_override("font_size", 22)
		continue_button.focus_mode = Control.FOCUS_NONE
