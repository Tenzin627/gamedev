extends ContentDefinition
class_name CreatureAIProfileDefinition

@export_range(0.0, 400.0, 1.0) var move_speed: float = 42.0
@export_range(0.05, 2.0, 0.05) var evaluation_interval: float = 0.25
@export_range(16.0, 512.0, 1.0) var notice_radius: float = 170.0
@export_range(8.0, 256.0, 1.0) var personal_space_radius: float = 58.0
@export_range(16.0, 512.0, 1.0) var flee_until_distance: float = 150.0
@export_range(16.0, 512.0, 1.0) var curiosity_stop_distance: float = 88.0
@export_range(0.0, 10.0, 0.1) var idle_weight: float = 1.0
@export_range(0.0, 10.0, 0.1) var wander_weight: float = 2.0
@export_range(0.0, 10.0, 0.1) var curiosity_weight: float = 0.0
@export_range(0.0, 10.0, 0.1) var flee_weight: float = 5.0
@export_range(0.0, 5.0, 0.05) var score_jitter: float = 0.35
@export_range(0.1, 20.0, 0.1) var min_idle_seconds: float = 0.8
@export_range(0.1, 30.0, 0.1) var max_idle_seconds: float = 2.0
@export_range(0.1, 20.0, 0.1) var min_wander_seconds: float = 1.1
@export_range(0.1, 30.0, 0.1) var max_wander_seconds: float = 3.4
@export_range(1.0, 128.0, 1.0) var wander_reach_distance: float = 18.0

func validate_definition() -> PackedStringArray:
    var errors: PackedStringArray = super.validate_definition()
    if move_speed <= 0.0:
        errors.append("AI profile %s move_speed must be positive" % String(content_id))
    if notice_radius < personal_space_radius:
        errors.append("AI profile %s notice_radius should be >= personal_space_radius" % String(content_id))
    if min_idle_seconds > max_idle_seconds:
        errors.append("AI profile %s idle range is inverted" % String(content_id))
    if min_wander_seconds > max_wander_seconds:
        errors.append("AI profile %s wander range is inverted" % String(content_id))
    return errors
