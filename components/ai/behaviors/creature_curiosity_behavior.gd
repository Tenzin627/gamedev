extends CreatureAIBehavior
class_name CreatureCuriosityBehavior

func evaluate_score(context: CreatureAIContext) -> float:
    if not enabled or context.profile == null or context.profile.curiosity_weight <= 0.0:
        return -INF
    var target: Node2D = context.get_player()
    if target == null:
        return -INF
    var distance: float = context.get_player_distance()
    if distance > context.profile.notice_radius or distance <= context.profile.personal_space_radius:
        return -INF
    return context.profile.curiosity_weight + float(behavior_priority)

func get_desired_velocity(context: CreatureAIContext, _delta: float) -> Vector2:
    if context.body == null or context.profile == null:
        return Vector2.ZERO
    var target: Node2D = context.get_player()
    if target == null:
        return Vector2.ZERO
    var distance: float = context.body.global_position.distance_to(target.global_position)
    if distance <= context.profile.curiosity_stop_distance:
        return Vector2.ZERO
    return context.body.global_position.direction_to(target.global_position) * context.profile.move_speed * 0.72
