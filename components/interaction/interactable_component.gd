extends Area2D
class_name InteractableComponent

signal interaction_requested(action: StringName, interactor: Node)
signal enabled_changed(enabled: bool)

@export var action_name: StringName = InteractionActions.INTERACT
@export var prompt_text: String = "Interact"
@export var unavailable_text: String = "Can't interact right now."
@export var interaction_priority: int = 0
@export var enabled: bool = true:
    set(value):
        if enabled == value:
            return
        enabled = value
        # Keep the Area2D detectable even while interaction is unavailable. This
        # lets the Interactor return useful failure feedback without making the
        # object focusable or actionable.
        enabled_changed.emit(enabled)
@export var interaction_point_path: NodePath

func can_interact(_interactor: Node) -> bool:
    return enabled and is_inside_tree()

func get_prompt_text(_interactor: Node) -> String:
    return prompt_text

func get_interaction_priority(_interactor: Node) -> int:
    return interaction_priority

func get_unavailable_text(_interactor: Node) -> String:
    return unavailable_text

func get_interaction_position() -> Vector2:
    if not interaction_point_path.is_empty():
        var point := get_node_or_null(interaction_point_path)
        if point is Node2D:
            return (point as Node2D).global_position
    return global_position

func request_interaction(interactor: Node) -> bool:
    if not can_interact(interactor):
        return false
    interaction_requested.emit(action_name, interactor)
    return true
