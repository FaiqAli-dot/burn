extends Control
## Premium brand splash. Tap or auto-advance to main menu.

@onready var brand: Label = $Brand
@onready var tagline: Label = $Tagline
@onready var hint: Label = $Hint
@onready var flame: TextureRect = $FlameMark
@onready var backdrop: ColorRect = $Backdrop

var _done: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	var mark := MaterialVisualCatalog.brand_flame()
	if mark and flame:
		flame.texture = mark
	brand.modulate.a = 0.0
	tagline.modulate.a = 0.0
	hint.modulate.a = 0.0
	flame.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(flame, "modulate:a", 1.0, 0.5)
	tw.parallel().tween_property(brand, "modulate:a", 1.0, 0.55).set_delay(0.12)
	tw.tween_property(tagline, "modulate:a", 0.85, 0.4)
	tw.tween_property(hint, "modulate:a", 0.55, 0.35)
	var pulse := create_tween().set_loops()
	pulse.tween_property(flame, "scale", Vector2(1.04, 1.06), 0.75).set_trans(Tween.TRANS_SINE)
	pulse.tween_property(flame, "scale", Vector2(0.97, 0.96), 0.75).set_trans(Tween.TRANS_SINE)
	get_tree().create_timer(3.2).timeout.connect(_advance)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		_advance()
	elif event is InputEventMouseButton and event.pressed:
		_advance()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		_advance()


func _advance() -> void:
	if _done:
		return
	_done = true
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.28)
	tw.tween_callback(func() -> void: GameManager.go_main_menu())
