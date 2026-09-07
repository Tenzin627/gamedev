extends CreatureAIBehavior
class_name CreatureIdleBehavior

var _remaining_seconds: float = 0.0

func evaluate_score(context: CreatureAIContext) -> float:
    if not enabled or context.profile == null:
        return -INF
    return context.profile.idle_weight + float(behavior_priority)

func enter_behavior(context: CreatureAIContext) -> void:
    if context.profile == null or context.rng == null:
        _remaining_seconds = 1.0
        return
    _remaining_seconds = context.rng.randf_range(context.profile.min_idle_seconds, context.profile.max_idle_seconds)

func get_desired_velocity(_context: CreatureAIContext, delta: float) -> Vector2:
    _remaining_seconds -= delta
    return Vector2.ZERO
