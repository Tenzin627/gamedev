extends Node2D
class_name NPCActor

signal dialogue_requested(npc_id: StringName, dialogue_id: StringName)

@export var npc_definition_id: StringName = &""
@export var dialogue_override_id: StringName = &""

@onready var interactable: InteractableComponent = $Interactable
@onready var visual: Sprite2D = $Visual
var _definition: NPCDefinition = null

func _ready() -> void:
    add_to_group(&"npc_actor")
    _definition = ContentDB.get_definition(npc_definition_id) as NPCDefinition
    if _definition == null:
        push_error("NPCActor could not resolve NPC: %s" % String(npc_definition_id))
        interactable.enabled = false
        return
    interactable.prompt_text = "Talk to %s" % _definition.display_name
    if not interactable.interaction_requested.is_connected(_on_interaction_requested):
        interactable.interaction_requested.connect(_on_interaction_requested)
    if visual != null:
        visual.texture = _definition.world_texture

func _on_interaction_requested(_action: StringName, _interactor: Node) -> void:
    if _definition == null:
        return
    var dialogue_id: StringName = dialogue_override_id if dialogue_override_id != &"" else _definition.default_dialogue_id
    if dialogue_id != &"":
        dialogue_requested.emit(_definition.content_id, dialogue_id)

