extends Node
class_name WorldStateCollisionResponder

@export var binding_path: NodePath = NodePath("../WorldStateBinding")
@export var collision_shape_paths: Array[NodePath] = []
@export var collision_enabled_when_active: bool = false
@export var collision_enabled_when_inactive: bool = true

var _binding: WorldStateBindingComponent = null

func _ready() -> void:
    _binding = get_node_or_null(binding_path) as WorldStateBindingComponent
    if _binding == null:
        push_warning("WorldStateCollisionResponder could not resolve binding")
        return
    if not _binding.active_changed.is_connected(_on_active_changed):
        _binding.active_changed.connect(_on_active_changed)
    _apply_collision_state(_binding.is_active())

func _on_active_changed(active: bool) -> void:
    _apply_collision_state(active)

func _apply_collision_state(active: bool) -> void:
    var enabled: bool = collision_enabled_when_active if active else collision_enabled_when_inactive
    for shape_path: NodePath in collision_shape_paths:
        var node: Node = get_node_or_null(shape_path)
        if node is CollisionShape2D:
            (node as CollisionShape2D).set_deferred("disabled", not enabled)
        elif node is CollisionPolygon2D:
            (node as CollisionPolygon2D).set_deferred("disabled", not enabled)
