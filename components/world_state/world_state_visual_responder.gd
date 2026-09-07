extends Node
class_name WorldStateVisualResponder

@export var binding_path: NodePath = NodePath("../WorldStateBinding")
@export var active_visual_path: NodePath = NodePath("../ActiveVisual")
@export var inactive_visual_path: NodePath = NodePath("../InactiveVisual")

var _binding: WorldStateBindingComponent = null
var _active_visual: CanvasItem = null
var _inactive_visual: CanvasItem = null

func _ready() -> void:
    _binding = get_node_or_null(binding_path) as WorldStateBindingComponent
    _active_visual = get_node_or_null(active_visual_path) as CanvasItem
    _inactive_visual = get_node_or_null(inactive_visual_path) as CanvasItem
    if _binding == null:
        push_warning("WorldStateVisualResponder could not resolve binding")
        return
    if not _binding.active_changed.is_connected(_on_active_changed):
        _binding.active_changed.connect(_on_active_changed)
    _apply_visual_state(_binding.is_active())

func _on_active_changed(active: bool) -> void:
    _apply_visual_state(active)

func _apply_visual_state(active: bool) -> void:
    if _active_visual != null:
        _active_visual.visible = active
    if _inactive_visual != null:
        _inactive_visual.visible = not active
