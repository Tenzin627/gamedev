extends Node

const MUSIC_BUS := "Music"
const SFX_BUS := "SFX"

func _ready() -> void:
    _ensure_bus(MUSIC_BUS)
    _ensure_bus(SFX_BUS)
    _apply_saved_levels()
    SettingsService.setting_changed.connect(_on_setting_changed)

func play_one_shot(stream: AudioStream, bus: StringName = &"SFX", volume_db: float = 0.0) -> AudioStreamPlayer:
    if stream == null:
        return null
    var player := AudioStreamPlayer.new()
    player.stream = stream
    player.bus = String(bus)
    player.volume_db = volume_db
    add_child(player)
    player.finished.connect(player.queue_free)
    player.play()
    return player

func set_bus_volume(bus_name: StringName, db: float) -> void:
    var index := AudioServer.get_bus_index(String(bus_name))
    if index >= 0:
        AudioServer.set_bus_volume_db(index, db)

func _ensure_bus(bus_name: String) -> void:
    if AudioServer.get_bus_index(bus_name) >= 0:
        return
    AudioServer.add_bus()
    var index := AudioServer.bus_count - 1
    AudioServer.set_bus_name(index, bus_name)

func _apply_saved_levels() -> void:
    set_bus_volume(&"Master", float(SettingsService.get_value(&"audio", &"master_db", 0.0)))
    set_bus_volume(&"Music", float(SettingsService.get_value(&"audio", &"music_db", -3.0)))
    set_bus_volume(&"SFX", float(SettingsService.get_value(&"audio", &"sfx_db", 0.0)))

func _on_setting_changed(section: StringName, key: StringName, _value: Variant) -> void:
    if section == &"audio":
        _apply_saved_levels()
