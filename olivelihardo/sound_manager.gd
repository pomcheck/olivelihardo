extends Node

const SAMPLE_RATE: int = 22050
const VOICES_PER_EFFECT: int = 4
const MUSIC_TRACKS: Array[AudioStream] = [
	preload("res://Goat Simulator Main Theme.mp3"),
	preload("res://Spider-Man The Animated Series (Genesis) Music - Fun House.mp3"),
]

var _effect_players: Dictionary = {}
var _music_player: AudioStreamPlayer
var _music_track_index: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for effect_name: StringName in [&"aggro", &"attack", &"hit", &"respawn"]:
		var voices: Array[AudioStreamPlayer] = []
		var effect_stream: AudioStreamWAV = _make_effect(effect_name)
		var effect_player: AudioStreamPlayer
		for voice_index: int in range(VOICES_PER_EFFECT):
			effect_player = AudioStreamPlayer.new()
			effect_player.name = "%sVoice%d" % [effect_name, voice_index]
			effect_player.stream = effect_stream
			effect_player.volume_db = -4.0
			add_child(effect_player)
			voices.append(effect_player)
		_effect_players[effect_name] = voices

	_music_player = AudioStreamPlayer.new()
	_music_player.name = "ShowroomMusic"
	_music_player.volume_db = -9.0
	_music_player.finished.connect(_play_next_music_track)
	add_child(_music_player)
	_play_next_music_track()


func play_sfx(effect_name: StringName) -> void:
	if not _effect_players.has(effect_name):
		push_warning("Unknown sound effect: %s" % effect_name)
		return

	var voices: Array[AudioStreamPlayer] = _effect_players[effect_name]
	for effect_player: AudioStreamPlayer in voices:
		if not effect_player.playing:
			effect_player.play()
			return
	voices[0].play()


func _play_next_music_track() -> void:
	_music_player.stream = MUSIC_TRACKS[_music_track_index]
	_music_player.play()
	_music_track_index = (_music_track_index + 1) % MUSIC_TRACKS.size()


func _make_effect(effect_name: StringName) -> AudioStreamWAV:
	var duration: float = 0.18
	match effect_name:
		&"aggro":
			duration = 0.42
		&"attack":
			duration = 0.28
		&"hit":
			duration = 0.34
		&"respawn":
			duration = 0.48

	var frame_count: int = int(SAMPLE_RATE * duration)
	var samples: PackedByteArray = PackedByteArray()
	samples.resize(frame_count * 2)
	var base_frequency: float = 180.0
	match effect_name:
		&"aggro":
			base_frequency = 230.0
		&"attack":
			base_frequency = 520.0
		&"hit":
			base_frequency = 78.0
		&"respawn":
			base_frequency = 390.0

	for frame: int in range(frame_count):
		var time: float = float(frame) / SAMPLE_RATE
		var progress: float = time / duration
		var envelope: float = pow(1.0 - progress, 2.0)
		var frequency: float = base_frequency
		match effect_name:
			&"aggro":
				frequency = lerpf(base_frequency, 560.0, progress)
			&"attack", &"hit":
				frequency = lerpf(base_frequency, 95.0, progress)
			&"respawn":
				frequency = lerpf(base_frequency, 880.0, progress)

		var tone: float = sin(TAU * frequency * time) * 0.48
		if effect_name == &"aggro":
			tone += sin(TAU * frequency * 1.5 * time) * 0.2
		if effect_name == &"attack" or effect_name == &"hit":
			tone += randf_range(-0.2, 0.2) * (1.0 - progress)
		var sample_value: float = clampf(tone * envelope, -1.0, 1.0)
		samples.encode_s16(frame * 2, int(sample_value * 32767.0))

	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = samples
	return stream
