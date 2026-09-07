extends CreatureAIBehavior
class_name CreatureFleeBehavior

func evaluate_score(context: CreatureAIContext) -> float:
    if not enabled or context.profile == null:
        return -INF
    var target: Node2D = context.get_player()
    if target == null:
        return -INF
    var distance: float = context.get_player_distance()
    if distance > context.profile.notice_radius:
        return -INF
    var closeness: float = 1.0 - clampf(distance / maxf(context.profile.notice_radius, 1.0), 0.0, 1.0)
    return context.profile.flee_weight + (closeness * context.profile.flee_weight) + float(behavior_priority)

func get_desired_velocity(context: CreatureAIContext, _delta: float) -> Vector2:
    if context.body == null or context.profile == null:
        return Vector2.ZERO
    var target: Node2D = context.get_player()
    if target == null:
        return Vector2.ZERO
    var distance: float = context.body.global_position.distance_to(target.global_position)
    if distance >= context.profile.flee_until_distance:
        return Vector2.ZERO
    var direction: Vector2 = target.global_position.direction_to(context.body.global_position)
    if direction.is_zero_approx():
        direction = Vector2.RIGHT
    return direction * context.profile.move_speed * 1.20
