extends CreatureAIBehavior
class_name CreatureReturnHabitatBehavior

@export_range(1.0, 10000.0, 1.0) var outside_habitat_score: float = 1000.0

func evaluate_score(context: CreatureAIContext) -> float:
    if not enabled or context.body == null or context.habitat == null:
        return -INF
    if context.habitat.contains_global_position(context.body.global_position):
        return -INF
    return outside_habitat_score + float(behavior_priority)

func get_desired_velocity(context: CreatureAIContext, _delta: float) -> Vector2:
    if context.body == null or context.profile == null:
        return Vector2.ZERO
    var target: Vector2 = context.home_position
    if context.habitat != null:
        target = context.habitat.global_position
    return context.body.global_position.direction_to(target) * context.profile.move_speed * 1.10
