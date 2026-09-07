extends Node
class_name CreatureAIBehavior

@export var behavior_id: StringName = &"behavior.base"
@export var enabled: bool = true
@export_range(-1000, 1000, 1) var behavior_priority: int = 0

func evaluate_score(_context: CreatureAIContext) -> float:
    return -INF

func enter_behavior(_context: CreatureAIContext) -> void:
    pass

func exit_behavior(_context: CreatureAIContext) -> void:
    pass

func get_desired_velocity(_context: CreatureAIContext, _delta: float) -> Vector2:
    return Vector2.ZERO
