extends Node2D
class_name StatefulWorldObject2D

signal persistent_state_changed(state_key: StringName, active: bool)

enum ObjectStyle {
    BRIDGE,
    ROUTE,
    WAYMARK,
}

@export var state_key: StringName = &""
@export_enum("Bridge", "Route", "Waymark") var object_style: int = ObjectStyle.BRIDGE
@export var default_active: bool = false
@export var inactive_prompt_text: String = "Repair"
@export var active_prompt_text: String = "Repaired"
@export var interaction_enabled_when_inactive: bool = true
@export var interaction_enabled_when_active: bool = true
@export var collision_enabled_when_inactive: bool = true
@export var collision_enabled_when_active: bool = false
@export var navigation_obstacle_when_inactive: bool = true
@export var navigation_obstacle_when_active: bool = false
@export var navigation_radius: float = 62.0
@export var target_active_on_interaction: bool = true
@export var toggle_on_interact: bool = false

var _binding: WorldStateBindingComponent = null

func _enter_tree() -> void:
    _configure_children_before_ready()

func _ready() -> void:
    add_to_group(&"world_state_object")
    _binding = get_node_or_null(^"WorldStateBinding") as WorldStateBindingComponent
    if _binding != null:
        if not _binding.active_changed.is_connected(_on_binding_active_changed):
            _binding.active_changed.connect(_on_binding_active_changed)
        persistent_state_changed.emit(state_key, _binding.is_active())

func is_active() -> bool:
    if _binding == null:
        return default_active
    return _binding.is_active()

func _configure_children_before_ready() -> void:
    var binding: WorldStateBindingComponent = get_node_or_null(^"WorldStateBinding") as WorldStateBindingComponent
    if binding != null:
        binding.state_key = state_key
        binding.default_active = default_active

    var inactive_visual: WorldStateVariantVisual2D = get_node_or_null(^"InactiveVisual") as WorldStateVariantVisual2D
    if inactive_visual != null:
        inactive_visual.visual_kind = object_style
        inactive_visual.active_variant = false

    var active_visual: WorldStateVariantVisual2D = get_node_or_null(^"ActiveVisual") as WorldStateVariantVisual2D
    if active_visual != null:
        active_visual.visual_kind = object_style
        active_visual.active_variant = true

    var interaction_responder: WorldStateInteractionResponder = get_node_or_null(^"InteractionResponder") as WorldStateInteractionResponder
    if interaction_responder != null:
        interaction_responder.inactive_prompt_text = inactive_prompt_text
        interaction_responder.active_prompt_text = active_prompt_text
        interaction_responder.enabled_when_inactive = interaction_enabled_when_inactive
        interaction_responder.enabled_when_active = interaction_enabled_when_active

    var collision_responder: WorldStateCollisionResponder = get_node_or_null(^"CollisionResponder") as WorldStateCollisionResponder
    if collision_responder != null:
        collision_responder.collision_enabled_when_inactive = collision_enabled_when_inactive
        collision_responder.collision_enabled_when_active = collision_enabled_when_active

    var navigation_responder: WorldStateNavigationResponder = get_node_or_null(^"NavigationResponder") as WorldStateNavigationResponder
    if navigation_responder != null:
        navigation_responder.obstacle_enabled_when_inactive = navigation_obstacle_when_inactive
        navigation_responder.obstacle_enabled_when_active = navigation_obstacle_when_active

    var obstacle: NavigationObstacle2D = get_node_or_null(^"NavigationObstacle2D") as NavigationObstacle2D
    if obstacle != null:
        obstacle.radius = navigation_radius

    var setter: WorldStateSetterComponent = get_node_or_null(^"StateSetter") as WorldStateSetterComponent
    if setter != null:
        setter.target_active = target_active_on_interaction
        setter.toggle_on_interact = toggle_on_interact

func _on_binding_active_changed(active: bool) -> void:
    persistent_state_changed.emit(state_key, active)
