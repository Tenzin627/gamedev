extends CreatureAIBehavior
class_name CreatureWanderBehavior

var _target_position: Vector2 = Vector2.ZERO
var _remaining_seconds: float = 0.0

func evaluate_score(context: CreatureAIContext) -> float:
    if not enabled or context.profile == null or context.habitat == null:
        return -INF
    return context.profile.wander_weight + float(behavior_priority)

func enter_behavior(context: CreatureAIContext) -> void:
    _choose_target(context)

func get_desired_velocity(context: CreatureAIContext, delta: float) -> Vector2:
    if context.body == null or context.habitat == null or context.profile == null:
        return Vector2.ZERO
    _remaining_seconds -= delta
    var distance: float = context.body.global_position.distance_to(_target_position)
    if _remaining_seconds <= 0.0 or distance <= context.profile.wander_reach_distance or not context.habitat.contains_global_position(_target_position):
        _choose_target(context)
        distance = context.body.global_position.distance_to(_target_position)
    if distance <= context.profile.wander_reach_distance:
        return Vector2.ZERO
    return context.body.global_position.direction_to(_target_position) * context.profile.move_speed

func _choose_target(context: CreatureAIContext) -> void:
    if context.habitat == null or context.rng == null or context.profile == null:
        _target_position = context.home_position
        _remaining_seconds = 1.0
        return
    _target_position = context.habitat.get_random_spawn_position(context.rng)
    _remaining_seconds = context.rng.randf_range(context.profile.min_wander_seconds, context.profile.max_wander_seconds)
