extends Node
class_name WorldStateInteractionResponder

@export var binding_path: NodePath = NodePath("../WorldStateBinding")
@export var interactable_path: NodePath = NodePath("../Interactable")
@export var enabled_when_active: bool = true
@export var enabled_when_inactive: bool = true
@export var active_prompt_text: String = "Active"
@export var inactive_prompt_text: String = "Interact"
@export var active_action_name: StringName = &"interact"
@export var inactive_action_name: StringName = &"interact"

var _binding: WorldStateBindingComponent = null
var _interactable: InteractableComponent = null

func _ready() -> void:
    _binding = get_node_or_null(binding_path) as WorldStateBindingComponent
    _interactable = get_node_or_null(interactable_path) as InteractableComponent
    if _binding == null or _interactable == null:
        push_warning("WorldStateInteractionResponder could not resolve binding/interactable")
        return
    if not _binding.active_changed.is_connected(_on_active_changed):
        _binding.active_changed.connect(_on_active_changed)
    _apply_interaction_state(_binding.is_active())

func _on_active_changed(active: bool) -> void:
    _apply_interaction_state(active)

func _apply_interaction_state(active: bool) -> void:
    if _interactable == null:
        return
    if active:
        _interactable.enabled = enabled_when_active
        _interactable.prompt_text = active_prompt_text
        _interactable.action_name = active_action_name
    else:
        _interactable.enabled = enabled_when_inactive
        _interactable.prompt_text = inactive_prompt_text
        _interactable.action_name = inactive_action_name
