extends Node2D
class_name CraftingStation

signal station_requested(station_tags: Array[StringName], title: String)

@export var station_title: String = "Crafting"
@export var station_tags: Array[StringName] = [&"crafting"]
@export var prompt_text: String = "Craft"
@export var workbench_texture: Texture2D
@export var hearth_texture: Texture2D
@onready var visual: Sprite2D = $Visual
@onready var interactable: InteractableComponent = $Interactable

func _ready() -> void:
    add_to_group(&"crafting_station")
    interactable.prompt_text = prompt_text
    interactable.interaction_requested.connect(_on_interaction_requested)
    if visual != null:
        visual.texture = hearth_texture if &"cooking" in station_tags else workbench_texture

func _on_interaction_requested(_action: StringName, _interactor: Node) -> void:
    station_requested.emit(station_tags.duplicate(), station_title)

