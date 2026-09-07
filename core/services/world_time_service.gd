extends Node

signal time_changed(day: int, hour: int, minute: int, total_game_minutes: int)
signal minutes_advanced(delta_minutes: int, total_game_minutes: int)
signal running_changed(running: bool)

const MINUTES_PER_DAY: int = 1440
const DEFAULT_START_MINUTES: int = 480
const SESSION_KEY: StringName = &"world_time"

var game_minutes_per_real_second: float = 2.0
var running: bool = true
var _total_game_minutes: int = DEFAULT_START_MINUTES
var _minute_accumulator: float = 0.0

func _ready() -> void:
    if not GameSession.session_started.is_connected(_on_session_started):
        GameSession.session_started.connect(_on_session_started)
    if not GameSession.session_imported.is_connected(_on_session_imported):
        GameSession.session_imported.connect(_on_session_imported)
    _restore_from_session()
    _emit_time_changed()

func _process(delta: float) -> void:
    if not running or game_minutes_per_real_second <= 0.0:
        return
    _minute_accumulator += delta * game_minutes_per_real_second
    var whole_minutes: int = int(floor(_minute_accumulator))
    if whole_minutes <= 0:
        return
    _minute_accumulator -= float(whole_minutes)
    advance_minutes(whole_minutes)

func set_running(value: bool) -> void:
    if running == value:
        return
    running = value
    running_changed.emit(running)

func set_total_game_minutes(value: int) -> void:
    _total_game_minutes = maxi(value, 0)
    _minute_accumulator = 0.0
    _persist_to_session()
    _emit_time_changed()

func advance_minutes(delta_minutes: int) -> void:
    if delta_minutes <= 0:
        return
    _total_game_minutes += delta_minutes
    _persist_to_session()
    minutes_advanced.emit(delta_minutes, _total_game_minutes)
    _emit_time_changed()

func get_total_game_minutes() -> int:
    return _total_game_minutes

func get_day() -> int:
    return int(floor(float(_total_game_minutes) / float(MINUTES_PER_DAY))) + 1

func get_minute_of_day() -> int:
    return _total_game_minutes % MINUTES_PER_DAY

func get_hour() -> int:
    return int(floor(float(get_minute_of_day()) / 60.0))

func get_minute() -> int:
    return get_minute_of_day() % 60

func get_time_of_day_tag() -> StringName:
    var hour: int = get_hour()
    if hour >= 5 and hour < 8:
        return &"dawn"
    if hour >= 8 and hour < 18:
        return &"day"
    if hour >= 18 and hour < 21:
        return &"dusk"
    return &"night"

func get_formatted_time() -> String:
    return "Day %d  %02d:%02d" % [get_day(), get_hour(), get_minute()]

func export_state() -> Dictionary:
    return {
        "total_game_minutes": _total_game_minutes,
        "running": running,
        "game_minutes_per_real_second": game_minutes_per_real_second,
    }

func import_state(data: Dictionary) -> void:
    _total_game_minutes = maxi(int(data.get("total_game_minutes", DEFAULT_START_MINUTES)), 0)
    running = bool(data.get("running", true))
    game_minutes_per_real_second = maxf(float(data.get("game_minutes_per_real_second", 2.0)), 0.0)
    _minute_accumulator = 0.0
    _emit_time_changed()
    running_changed.emit(running)

func reset_to_default() -> void:
    _total_game_minutes = DEFAULT_START_MINUTES
    _minute_accumulator = 0.0
    running = true
    _persist_to_session()
    _emit_time_changed()
    running_changed.emit(running)

func _persist_to_session() -> void:
    GameSession.set_value(SESSION_KEY, export_state())

func _restore_from_session() -> void:
    var stored: Variant = GameSession.get_value(SESSION_KEY, {})
    if stored is Dictionary and not Dictionary(stored).is_empty():
        import_state(Dictionary(stored))
        return
    _persist_to_session()

func _emit_time_changed() -> void:
    time_changed.emit(get_day(), get_hour(), get_minute(), _total_game_minutes)

func _on_session_started(_profile_id: String) -> void:
    reset_to_default()

func _on_session_imported() -> void:
    _restore_from_session()
