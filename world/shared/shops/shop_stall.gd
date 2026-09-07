extends Node2D
class_name ShopStall

signal shop_requested(shop_id: StringName, start_in_sell_mode: bool)

@export var shop_id: StringName = &""
@export var prompt_text: String = "Browse market stall"
@export var start_in_sell_mode: bool = false
@onready var interactable: InteractableComponent = $Interactable

func _ready() -> void:
    add_to_group(&"shop_stall")
    interactable.prompt_text = prompt_text
    interactable.interaction_requested.connect(_on_interaction_requested)

func _on_interaction_requested(_action: StringName, _interactor: Node) -> void:
    if shop_id != &"":
        shop_requested.emit(shop_id, start_in_sell_mode)
