extends Node
class_name WorldStateNavigationResponder

@export var binding_path: NodePath = NodePath("../WorldStateBinding")
@export var obstacle_paths: Array[NodePath] = []
@export var obstacle_enabled_when_active: bool = false
@export var obstacle_enabled_when_inactive: bool = true

var _binding: WorldStateBindingComponent = null

func _ready() -> void:
    _binding = get_node_or_null(binding_path) as WorldStateBindingComponent
    if _binding == null:
        push_warning("WorldStateNavigationResponder could not resolve binding")
        return
    if not _binding.active_changed.is_connected(_on_active_changed):
        _binding.active_changed.connect(_on_active_changed)
    _apply_navigation_state(_binding.is_active())

func _on_active_changed(active: bool) -> void:
    _apply_navigation_state(active)

func _apply_navigation_state(active: bool) -> void:
    var enabled: bool = obstacle_enabled_when_active if active else obstacle_enabled_when_inactive
    for obstacle_path: NodePath in obstacle_paths:
        var obstacle: NavigationObstacle2D = get_node_or_null(obstacle_path) as NavigationObstacle2D
        if obstacle != null:
            obstacle.avoidance_enabled = enabled
