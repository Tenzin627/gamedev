extends Node
class_name WorldStateSetterComponent

signal state_write_requested(state_key: StringName, active: bool, interactor: Node)
signal state_write_completed(state_key: StringName, active: bool, interactor: Node)

@export var binding_path: NodePath = NodePath("../WorldStateBinding")
@export var interactable_path: NodePath = NodePath("../Interactable")
@export var target_active: bool = true
@export var toggle_on_interact: bool = false
@export var ignore_if_already_target: bool = true

var _binding: WorldStateBindingComponent = null
var _interactable: InteractableComponent = null

func _ready() -> void:
    _binding = get_node_or_null(binding_path) as WorldStateBindingComponent
    _interactable = get_node_or_null(interactable_path) as InteractableComponent
    if _binding == null or _interactable == null:
        push_warning("WorldStateSetterComponent could not resolve binding/interactable")
        return
    if not _interactable.interaction_requested.is_connected(_on_interaction_requested):
        _interactable.interaction_requested.connect(_on_interaction_requested)

func _on_interaction_requested(_action: StringName, interactor: Node) -> void:
    if _binding == null:
        return
    var next_active: bool = target_active
    if toggle_on_interact:
        next_active = not _binding.is_active()
    elif ignore_if_already_target and _binding.is_active() == target_active:
        return
    state_write_requested.emit(_binding.state_key, next_active, interactor)
    _binding.set_active(next_active)
    state_write_completed.emit(_binding.state_key, next_active, interactor)
