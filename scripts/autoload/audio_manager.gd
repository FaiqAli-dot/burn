extends Node
## Event audio with throttling. Uses procedural tones — no external SFX packs.
## Headless / missing audio driver: all calls no-op safely.

var enabled: bool = true
var _player: AudioStreamPlayer
var _gen: AudioStreamGenerator
var _playback: AudioStreamGeneratorPlayback
var _cooldown: Dictionary = {}
var _mix_rate: float = 22050.0


func _ready() -> void:
	_player = AudioStreamPlayer.new()
	_player.name = "TonePlayer"
	_player.volume_db = -8.0
	add_child(_player)
	_gen = AudioStreamGenerator.new()
	_gen.mix_rate = _mix_rate
	_gen.buffer_length = 0.35
	_player.stream = _gen


func play_level_start() -> void:
	_beep("level_start", 220.0, 0.08, 0.12, 0.05)


func play_tap() -> void:
	_beep("tap", 480.0, 0.03, 0.06, 0.03)


func play_ignite() -> void:
	_beep("ignite", 320.0, 0.07, 0.18, 0.06)


func play_small_burn() -> void:
	_beep("small_burn", 180.0, 0.05, 0.1, 0.08)


func play_large_burn() -> void:
	_beep("large_burn", 140.0, 0.1, 0.22, 0.07)


func play_chain_step(step: int = 1) -> void:
	var f := 260.0 + clampf(float(step), 1.0, 12.0) * 18.0
	_beep("chain", f, 0.04, 0.09, 0.05)


func play_explosion() -> void:
	_beep("explosion", 90.0, 0.14, 0.28, 0.04, true)


func play_destroy() -> void:
	_beep("destroy", 200.0, 0.04, 0.08, 0.06)


func play_win() -> void:
	_beep("win_a", 392.0, 0.08, 0.12, 0.0)
	_beep("win_b", 523.0, 0.1, 0.18, 0.09)


func play_fail() -> void:
	_beep("fail", 150.0, 0.12, 0.2, 0.05)


func play_retry() -> void:
	_beep("retry", 300.0, 0.05, 0.1, 0.04)


func _beep(key: String, freq: float, dur: float, amp: float, min_gap: float, noisy: bool = false) -> void:
	if not enabled:
		return
	var now := Time.get_ticks_msec() / 1000.0
	if float(_cooldown.get(key, -999.0)) + min_gap > now:
		return
	_cooldown[key] = now
	if not is_inside_tree():
		return
	## Ensure playback is running.
	if not _player.playing:
		_player.play()
	_playback = _player.get_stream_playback() as AudioStreamGeneratorPlayback
	if _playback == null:
		return
	var frames := int(dur * _mix_rate)
	var to_fill := mini(frames, _playback.get_frames_available())
	for i in to_fill:
		var t := float(i) / _mix_rate
		var env := 1.0 - (float(i) / maxf(float(to_fill), 1.0))
		env = env * env
		var sample := sin(TAU * freq * t) * amp * env
		if noisy:
			sample += (randf() * 2.0 - 1.0) * amp * 0.35 * env
		_playback.push_frame(Vector2(sample, sample))
