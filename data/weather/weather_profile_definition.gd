extends ContentDefinition
class_name WeatherProfileDefinition

@export var default_weather_id: StringName = &"clear"
@export var entries: Array[Resource] = []

func validate_definition() -> PackedStringArray:
    var errors: PackedStringArray = super.validate_definition()
    if entries.is_empty():
        errors.append("Weather profile %s has no weather entries" % String(content_id))
    var seen_ids: Dictionary = {}
    var default_found: bool = false
    for entry_resource: Resource in entries:
        if not entry_resource is WeatherEntry:
            errors.append("Weather profile %s has a non-WeatherEntry resource" % String(content_id))
            continue
        var entry: WeatherEntry = entry_resource as WeatherEntry
        errors.append_array(entry.validate_entry())
        var key: String = String(entry.weather_id)
        if seen_ids.has(key):
            errors.append("Weather profile %s repeats weather_id %s" % [String(content_id), key])
        seen_ids[key] = true
        if entry.weather_id == default_weather_id:
            default_found = true
    if default_weather_id == &"":
        errors.append("Weather profile %s is missing default_weather_id" % String(content_id))
    elif not default_found:
        errors.append("Weather profile %s default_weather_id is not present in entries: %s" % [String(content_id), String(default_weather_id)])
    return errors

func get_entry(weather_id: StringName) -> WeatherEntry:
    for entry_resource: Resource in entries:
        if entry_resource is WeatherEntry:
            var entry: WeatherEntry = entry_resource as WeatherEntry
            if entry.weather_id == weather_id:
                return entry
    return null

func get_valid_entries() -> Array[WeatherEntry]:
    var result: Array[WeatherEntry] = []
    for entry_resource: Resource in entries:
        if entry_resource is WeatherEntry:
            result.append(entry_resource as WeatherEntry)
    return result
