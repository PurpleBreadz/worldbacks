extends Node
## Small original synthesizer: no external audio files, libraries, or services.
const RATE: int = 22050
var clips: Dictionary = {}
var music: AudioStreamPlayer
var ambience: AudioStreamPlayer
var audio_enabled: bool = true

func _ready() -> void:
	for bus_name: String in ["Music", "Ambience", "SFX"]:
		if AudioServer.get_bus_index(bus_name) < 0:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus_name)
	# Dummy output is used by headless validation. Avoid queuing inaudible
	# looping playback there (the dummy backend retains it during shutdown).
	audio_enabled = AudioServer.get_driver_name() != "Dummy"
	if not audio_enabled:
		return
	music = AudioStreamPlayer.new()
	music.bus = "Music"
	music.volume_db = -21.0
	music.stream = _make_bed(true)
	add_child(music)
	music.play()
	ambience = AudioStreamPlayer.new()
	ambience.bus = "Ambience"
	ambience.volume_db = -28.0
	ambience.stream = _make_bed(false)
	add_child(ambience)
	ambience.play()

func play(kind: String) -> void:
	if not audio_enabled or get_child_count() > 14:
		return
	if not clips.has(kind):
		clips[kind] = _make_effect(kind)
	var voice: AudioStreamPlayer = AudioStreamPlayer.new()
	voice.bus = "SFX"
	voice.volume_db = -12.0
	voice.stream = clips[kind]
	add_child(voice)
	voice.finished.connect(voice.queue_free)
	voice.play()

func _exit_tree() -> void:
	# Release looping playback before the audio server shuts down.
	for child: Node in get_children():
		if child is AudioStreamPlayer:
			child.stop()
			child.stream = null
	clips.clear()

func _wave(samples: PackedByteArray, length: int, loop: bool = false) -> AudioStreamWAV:
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.stereo = false
	stream.data = samples
	if loop:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = length
	return stream

func _make_effect(kind: String) -> AudioStreamWAV:
	var freq: float = 240.0
	var duration: float = 0.18
	var noise: float = 0.1
	match kind:
		"attack", "swing", "dodge":
			freq = 130.0
			noise = 0.65
		"hit", "hurt", "damage", "block":
			freq = 95.0
			noise = 0.45
		"parry", "deflect":
			freq = 880.0
			duration = 0.38
		"break", "posture_break", "stagger":
			freq = 58.0
			duration = 0.45
		"death", "boss_death":
			freq = 65.0
			duration = 0.8
		"heal", "waystone", "pickup", "build":
			freq = 440.0
			duration = 0.5
		"awaken":
			freq = 110.0
			duration = 1.5
	var length: int = int(RATE * duration)
	var samples: PackedByteArray = PackedByteArray()
	samples.resize(length * 2)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = kind.hash()
	for i: int in range(length):
		var t: float = float(i) / RATE
		var envelope: float = pow(1.0 - float(i) / length, 2.0) * minf(t * 150.0, 1.0)
		var tone: float = sin(TAU * freq * t - 35.0 * t * t) + 0.35 * sin(TAU * freq * 2.003 * t)
		var value: float = envelope * (tone * (1.0 - noise) + rng.randf_range(-1.0, 1.0) * noise) * 0.5
		samples.encode_s16(i * 2, int(clampf(value, -1.0, 1.0) * 32767.0))
	return _wave(samples, length)

func _make_bed(melodic: bool) -> AudioStreamWAV:
	var length: int = RATE * 8
	var samples: PackedByteArray = PackedByteArray()
	samples.resize(length * 2)
	var notes: Array[float] = [220.0, 0.0, 261.626, 0.0, 329.628, 293.665, 0.0, 196.0]
	for i: int in range(length):
		var t: float = float(i) / RATE
		var value: float = 0.0
		if melodic:
			var note: float = notes[int(t) % notes.size()]
			var phase: float = fmod(t, 1.0)
			value = sin(TAU * note * t) * exp(-phase * 4.0) * minf(phase * 50.0, 1.0) * 0.3
		else:
			value = (sin(TAU * 55.0 * t) * 0.2 + sin(TAU * 82.5 * t) * 0.15) * (0.65 + 0.35 * sin(TAU * t / 8.0))
		samples.encode_s16(i * 2, int(value * 32767.0))
	return _wave(samples, length, true)
