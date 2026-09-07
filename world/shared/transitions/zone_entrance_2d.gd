extends Node2D
class_name ZoneEntrance2D

signal travel_requested(destination_zone_id: StringName, destination_spawn_id: StringName)

@export var destination_zone_id: StringName = &""
@export var destination_spawn_id: StringName = &"default"
@export var prompt_text: String = "Travel"
@export var marker_color: Color = Color("#d6c68f")

@onready var interactable: InteractableComponent = $Interactable

func _ready() -> void:
    interactable.prompt_text = prompt_text
    interactable.action_name = &"travel"
    if not interactable.interaction_requested.is_connected(_on_interaction_requested):
        interactable.interaction_requested.connect(_on_interaction_requested)


func _on_interaction_requested(_action: StringName, _interactor: Node) -> void:
    if destination_zone_id == &"":
        push_warning("ZoneEntrance2D has no destination_zone_id")
        return
    travel_requested.emit(destination_zone_id, destination_spawn_id)
    SceneRouter.travel_to_zone(destination_zone_id, destination_spawn_id)
