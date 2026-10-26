extends Node
var effects: Dictionary = {}
var active: Array[AudioStreamPlayer] = []
var muted = false
var ambience: AudioStreamPlayer

func _ready() -> void:
	effects.step = tone(0.13, 72, 0.18, true)
	effects.ui = tone(0.12, 820, 0.1)
	effects.task = tone(0.4, 640, 0.1)
	effects.alarm = tone(0.7, 480, 0.12)
	effects.meeting = tone(0.55, 260, 0.13)
	effects.attack = tone(0.26, 95, 0.17, true)
	effects.rifle = tone(0.32, 115, 0.32, true)
	ambience = AudioStreamPlayer.new()
	var stream = tone(3.0, 48, 0.022)
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = 66150
	ambience.stream = stream
	add_child(ambience)
	ambience.play()

func tone(duration: float, frequency: float, amplitude: float, noise: bool = false) -> AudioStreamWAV:
	var data = PackedByteArray()
	var count = int(duration * 22050)
	data.resize(count * 2)
	var rng = RandomNumberGenerator.new()
	rng.seed = 88
	for i in count:
		var t = float(i) / 22050.0
		var envelope = exp(-t * 22.0) if noise else minf(t * 30.0, 1.0) * minf((duration - t) * 15.0, 1.0)
		var value = (sin(TAU * frequency * t) + 0.22 * sin(TAU * frequency * 2.0 * t)) * amplitude * envelope
		if noise:
			value += rng.randf_range(-0.03, 0.03) * envelope
		data.encode_s16(i * 2, int(clampf(value, -1, 1) * 32767.0))
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	stream.stereo = false
	stream.data = data
	return stream

func play_effect(key: String) -> void:
	if muted or not effects.has(key):
		return
	var player = AudioStreamPlayer.new()
	player.stream = effects[key]
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()

func toggle_mute() -> void:
	muted = not muted
	AudioServer.set_bus_mute(0, muted)

func stop_all() -> void:
	for child in get_children():
		if child is AudioStreamPlayer:
			child.stop()
			child.stream = null
	effects.clear()

func _exit_tree() -> void:
	stop_all()
