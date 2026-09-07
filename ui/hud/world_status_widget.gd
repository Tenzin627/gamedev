extends PanelContainer
class_name WorldStatusWidget

@onready var location_label: Label = $Margin/VBox/LocationLabel
@onready var time_label: Label = $Margin/VBox/Meta/TimeLabel
@onready var weather_label: Label = $Margin/VBox/Meta/WeatherLabel

var _ambient_controller: RegionAmbientController = null

func _ready() -> void:
    LungSaUIStyle.apply_panel(self, false)
    LungSaUIStyle.apply_title(location_label, 16)
    LungSaUIStyle.apply_muted(time_label, 12)
    LungSaUIStyle.apply_muted(weather_label, 12)
    if not WorldTimeService.time_changed.is_connected(_on_time_changed):
        WorldTimeService.time_changed.connect(_on_time_changed)
    if not SceneRouter.location_changed.is_connected(_on_location_changed):
        SceneRouter.location_changed.connect(_on_location_changed)
    _refresh_location(SceneRouter.current_region_id, SceneRouter.current_zone_id)
    _refresh_time()
    _refresh_weather()

func _exit_tree() -> void:
    if WorldTimeService.time_changed.is_connected(_on_time_changed):
        WorldTimeService.time_changed.disconnect(_on_time_changed)
    if SceneRouter.location_changed.is_connected(_on_location_changed):
        SceneRouter.location_changed.disconnect(_on_location_changed)
    _disconnect_ambient_controller()

func bind_ambient_controller(controller: RegionAmbientController) -> void:
    _disconnect_ambient_controller()
    _ambient_controller = controller
    if _ambient_controller != null and not _ambient_controller.weather_changed.is_connected(_on_weather_changed):
        _ambient_controller.weather_changed.connect(_on_weather_changed)
    _refresh_weather()

func _disconnect_ambient_controller() -> void:
    if _ambient_controller != null and is_instance_valid(_ambient_controller):
        if _ambient_controller.weather_changed.is_connected(_on_weather_changed):
            _ambient_controller.weather_changed.disconnect(_on_weather_changed)
    _ambient_controller = null

func _on_time_changed(_day: int, _hour: int, _minute: int, _total_game_minutes: int) -> void:
    _refresh_time()

func _on_weather_changed(_weather_id: StringName, _display_name: String, _remaining_game_minutes: int) -> void:
    _refresh_weather()

func _on_location_changed(region_id: StringName, zone_id: StringName, _spawn_id: StringName) -> void:
    _refresh_location(region_id, zone_id)

func _refresh_location(region_id: StringName, zone_id: StringName) -> void:
    if location_label == null:
        return
    var region: RegionDefinition = ContentDB.get_definition(region_id) as RegionDefinition
    var zone: ZoneDefinition = ContentDB.get_definition(zone_id) as ZoneDefinition
    var region_name: String = region.display_name if region != null else "Central Basin"
    var zone_name: String = zone.display_name if zone != null else "West Meadow"
    location_label.text = "%s  •  %s" % [region_name.to_upper(), zone_name.to_upper()]

func _refresh_time() -> void:
    if time_label != null:
        time_label.text = WorldTimeService.get_formatted_time()

func _refresh_weather() -> void:
    if weather_label == null:
        return
    if _ambient_controller == null or not is_instance_valid(_ambient_controller):
        weather_label.text = "Weather —"
        return
    weather_label.text = _ambient_controller.get_current_weather_display_name()
