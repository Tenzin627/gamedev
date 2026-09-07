extends Node

signal setting_changed(section: StringName, key: StringName, value: Variant)

const SETTINGS_PATH := "user://settings.cfg"

var _config := ConfigFile.new()
var _defaults := {
    "audio/master_db": 0.0,
    "audio/music_db": -3.0,
    "audio/sfx_db": 0.0,
    "accessibility/ui_scale": 1.0,
    "accessibility/reduced_shake": false,
    "accessibility/reduced_flash": false,
}

func _ready() -> void:
    load_settings()

func load_settings() -> void:
    _config = ConfigFile.new()
    _config.load(SETTINGS_PATH)
    _apply_defaults()

func save_settings() -> Error:
    return _config.save(SETTINGS_PATH)

func get_value(section: StringName, key: StringName, default_value: Variant = null) -> Variant:
    var fallback_key := "%s/%s" % [String(section), String(key)]
    var fallback: Variant = _defaults.get(fallback_key, default_value)
    return _config.get_value(String(section), String(key), fallback)

func set_value(section: StringName, key: StringName, value: Variant, save_now: bool = true) -> void:
    _config.set_value(String(section), String(key), value)
    setting_changed.emit(section, key, value)
    if save_now:
        save_settings()

func _apply_defaults() -> void:
    for composite_key in _defaults.keys():
        var parts: PackedStringArray = String(composite_key).split("/")
        if parts.size() != 2:
            continue
        if not _config.has_section_key(parts[0], parts[1]):
            _config.set_value(parts[0], parts[1], _defaults[composite_key])
