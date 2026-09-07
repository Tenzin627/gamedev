extends RegionLocalSystem
class_name RegionAmbientController

signal weather_changed(weather_id: StringName, display_name: String, remaining_game_minutes: int)
signal ambience_enabled_changed(enabled: bool)

@export var ambience_enabled: bool = true
@export var weather_enabled: bool = true

var current_weather_id: StringName = &"clear"
var weather_remaining_game_minutes: int = 0
var weather_roll_serial: int = 0
var _weather_profile: WeatherProfileDefinition = null

func _on_region_bound() -> void:
    _resolve_weather_profile()
    if not WorldTimeService.minutes_advanced.is_connected(_on_world_minutes_advanced):
        WorldTimeService.minutes_advanced.connect(_on_world_minutes_advanced)
    _ensure_weather_state()

func _exit_tree() -> void:
    if WorldTimeService.minutes_advanced.is_connected(_on_world_minutes_advanced):
        WorldTimeService.minutes_advanced.disconnect(_on_world_minutes_advanced)

func set_ambience_enabled(value: bool) -> void:
    if ambience_enabled == value:
        return
    ambience_enabled = value
    ambience_enabled_changed.emit(ambience_enabled)

func set_weather_enabled(value: bool) -> void:
    weather_enabled = value

func get_weather_profile() -> WeatherProfileDefinition:
    return _weather_profile

func get_current_weather_entry() -> WeatherEntry:
    if _weather_profile == null:
        return null
    return _weather_profile.get_entry(current_weather_id)

func get_current_weather_display_name() -> String:
    var entry: WeatherEntry = get_current_weather_entry()
    if entry == null:
        return "Clear"
    return entry.display_name

func get_environment_tags() -> Array[StringName]:
    var result: Array[StringName] = []
    result.append(StringName("weather.%s" % String(current_weather_id)))
    result.append(StringName("time.%s" % String(WorldTimeService.get_time_of_day_tag())))
    var entry: WeatherEntry = get_current_weather_entry()
    if entry != null and entry.ambience_tag != &"":
        result.append(StringName("ambience.%s" % String(entry.ambience_tag)))
    return result

func force_next_weather() -> void:
    if _weather_profile == null:
        _resolve_weather_profile()
    if _weather_profile == null:
        return
    _roll_next_weather(true)

func export_runtime_state() -> Dictionary:
    return {
        "ambience_enabled": ambience_enabled,
        "weather_enabled": weather_enabled,
        "current_weather_id": String(current_weather_id),
        "weather_remaining_game_minutes": weather_remaining_game_minutes,
        "weather_roll_serial": weather_roll_serial,
    }

func import_runtime_state(state: Dictionary) -> void:
    ambience_enabled = bool(state.get("ambience_enabled", ambience_enabled))
    weather_enabled = bool(state.get("weather_enabled", weather_enabled))
    current_weather_id = StringName(str(state.get("current_weather_id", String(current_weather_id))))
    weather_remaining_game_minutes = maxi(int(state.get("weather_remaining_game_minutes", weather_remaining_game_minutes)), 0)
    weather_roll_serial = maxi(int(state.get("weather_roll_serial", weather_roll_serial)), 0)
    if _weather_profile == null:
        _resolve_weather_profile()
    if _weather_profile != null and _weather_profile.get_entry(current_weather_id) == null:
        current_weather_id = _weather_profile.default_weather_id
        weather_remaining_game_minutes = 0
    _ensure_weather_state()
    ambience_enabled_changed.emit(ambience_enabled)

func _resolve_weather_profile() -> void:
    _weather_profile = null
    if region_root == null or region_root.zone_definition == null:
        return
    var profile_id: StringName = region_root.zone_definition.weather_profile_id
    if profile_id == &"":
        return
    _weather_profile = ContentDB.get_definition(profile_id) as WeatherProfileDefinition
    if _weather_profile == null:
        push_warning("RegionAmbientController could not resolve weather profile: %s" % String(profile_id))

func _ensure_weather_state() -> void:
    if _weather_profile == null:
        current_weather_id = &"clear"
        weather_remaining_game_minutes = 0
        weather_changed.emit(current_weather_id, "Clear", weather_remaining_game_minutes)
        return
    var entry: WeatherEntry = _weather_profile.get_entry(current_weather_id)
    if entry == null:
        current_weather_id = _weather_profile.default_weather_id
        entry = _weather_profile.get_entry(current_weather_id)
    if entry == null:
        var entries: Array[WeatherEntry] = _weather_profile.get_valid_entries()
        if entries.is_empty():
            weather_changed.emit(&"clear", "Clear", 0)
            return
        entry = entries[0]
        current_weather_id = entry.weather_id
    if weather_remaining_game_minutes <= 0:
        weather_remaining_game_minutes = maxi(entry.min_duration_game_minutes, 1)
    weather_changed.emit(current_weather_id, entry.display_name, weather_remaining_game_minutes)

func _on_world_minutes_advanced(delta_minutes: int, _total_game_minutes: int) -> void:
    if not weather_enabled or _weather_profile == null or delta_minutes <= 0:
        return
    weather_remaining_game_minutes -= delta_minutes
    var safety_iterations: int = 0
    while weather_remaining_game_minutes <= 0 and safety_iterations < 16:
        var overshoot: int = -weather_remaining_game_minutes
        _roll_next_weather(false)
        weather_remaining_game_minutes -= overshoot
        safety_iterations += 1
    var current_entry: WeatherEntry = get_current_weather_entry()
    if current_entry != null:
        weather_changed.emit(current_weather_id, current_entry.display_name, weather_remaining_game_minutes)

func _roll_next_weather(prefer_different: bool) -> void:
    if _weather_profile == null:
        return
    var candidates: Array[WeatherEntry] = _weather_profile.get_valid_entries()
    if candidates.is_empty():
        return
    var filtered: Array[WeatherEntry] = []
    if prefer_different and candidates.size() > 1:
        for candidate: WeatherEntry in candidates:
            if candidate.weather_id != current_weather_id:
                filtered.append(candidate)
    else:
        filtered = candidates
    if filtered.is_empty():
        filtered = candidates

    weather_roll_serial += 1
    var rng: RandomNumberGenerator = RandomNumberGenerator.new()
    var seed_text: String = "%s|day:%d|weather:%d" % [String(get_zone_id()), WorldTimeService.get_day(), weather_roll_serial]
    var seed_value: int = seed_text.hash()
    if seed_value < 0:
        seed_value = -seed_value
    rng.seed = seed_value

    var total_weight: float = 0.0
    for candidate: WeatherEntry in filtered:
        total_weight += maxf(candidate.weight, 0.0)
    if total_weight <= 0.0:
        return
    var roll: float = rng.randf_range(0.0, total_weight)
    var cumulative: float = 0.0
    var selected: WeatherEntry = filtered[filtered.size() - 1]
    for candidate: WeatherEntry in filtered:
        cumulative += maxf(candidate.weight, 0.0)
        if roll <= cumulative:
            selected = candidate
            break

    current_weather_id = selected.weather_id
    var min_duration: int = maxi(selected.min_duration_game_minutes, 1)
    var max_duration: int = maxi(selected.max_duration_game_minutes, min_duration)
    weather_remaining_game_minutes = rng.randi_range(min_duration, max_duration)
    weather_changed.emit(current_weather_id, selected.display_name, weather_remaining_game_minutes)
