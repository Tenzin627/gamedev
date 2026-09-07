extends Resource
class_name WeatherEntry

@export var weather_id: StringName = &"clear"
@export var display_name: String = "Clear"
@export_range(0.01, 1000.0, 0.01) var weight: float = 1.0
@export_range(1, 1440, 1) var min_duration_game_minutes: int = 120
@export_range(1, 2880, 1) var max_duration_game_minutes: int = 240
@export var ambience_tag: StringName = &"calm"

func validate_entry() -> PackedStringArray:
    var errors: PackedStringArray = PackedStringArray()
    if weather_id == &"":
        errors.append("Weather entry is missing weather_id")
    if display_name.strip_edges().is_empty():
        errors.append("Weather entry %s is missing display_name" % String(weather_id))
    if weight <= 0.0:
        errors.append("Weather entry %s must have positive weight" % String(weather_id))
    if min_duration_game_minutes < 1:
        errors.append("Weather entry %s min duration must be >= 1" % String(weather_id))
    if max_duration_game_minutes < min_duration_game_minutes:
        errors.append("Weather entry %s max duration must be >= min duration" % String(weather_id))
    return errors
