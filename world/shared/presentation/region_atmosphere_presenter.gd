extends CanvasModulate
class_name RegionAtmospherePresenter

var _ambient_controller: RegionAmbientController = null
var _region_root: RegionRoot = null

func _ready() -> void:
    if not WorldTimeService.time_changed.is_connected(_on_time_changed):
        WorldTimeService.time_changed.connect(_on_time_changed)
    call_deferred("_bind_region_ambient")
    _refresh_color()

func _exit_tree() -> void:
    if WorldTimeService.time_changed.is_connected(_on_time_changed):
        WorldTimeService.time_changed.disconnect(_on_time_changed)
    _disconnect_ambient()

func _bind_region_ambient() -> void:
    _region_root = _find_region_root()
    _disconnect_ambient()
    if _region_root != null:
        _ambient_controller = _region_root.get_local_system(&"AmbientController") as RegionAmbientController
    if _ambient_controller != null:
        if not _ambient_controller.weather_changed.is_connected(_on_weather_changed):
            _ambient_controller.weather_changed.connect(_on_weather_changed)
    _refresh_color()

func _disconnect_ambient() -> void:
    if _ambient_controller != null and is_instance_valid(_ambient_controller):
        if _ambient_controller.weather_changed.is_connected(_on_weather_changed):
            _ambient_controller.weather_changed.disconnect(_on_weather_changed)
    _ambient_controller = null

func _on_time_changed(_day: int, _hour: int, _minute: int, _total_game_minutes: int) -> void:
    _refresh_color()

func _on_weather_changed(_weather_id: StringName, _display_name: String, _remaining_game_minutes: int) -> void:
    _refresh_color()

func _refresh_color() -> void:
    var hour: int = WorldTimeService.get_hour()
    var base_color: Color = _get_time_color(hour)
    var weather_id: StringName = &"clear"
    if _ambient_controller != null and is_instance_valid(_ambient_controller):
        weather_id = _ambient_controller.current_weather_id
    match weather_id:
        &"drizzle":
            base_color = base_color.darkened(0.08)
        &"mist":
            base_color = base_color.lerp(Color(0.90, 0.93, 0.90, 1.0), 0.10)
        &"wind":
            base_color = base_color.lerp(Color(0.93, 0.96, 0.94, 1.0), 0.04)
        _:
            pass
    color = base_color

func _get_time_color(hour: int) -> Color:
    if hour >= 5 and hour < 8:
        return Color(0.88, 0.83, 0.72, 1.0)
    if hour >= 8 and hour < 18:
        return Color(1.0, 1.0, 1.0, 1.0)
    if hour >= 18 and hour < 21:
        return Color(0.86, 0.76, 0.70, 1.0)
    return Color(0.48, 0.56, 0.68, 1.0)

func _find_region_root() -> RegionRoot:
    var current: Node = get_parent()
    while current != null:
        if current is RegionRoot:
            return current as RegionRoot
        current = current.get_parent()
    return null
