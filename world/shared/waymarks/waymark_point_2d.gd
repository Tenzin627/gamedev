extends Node2D
class_name WaymarkPoint2D

signal waymark_activated(waymark_id: StringName)
signal travel_menu_requested(origin_waymark_id: StringName, interactor: Node)
signal activation_changed(waymark_id: StringName, active: bool)

@export var waymark_definition_id: StringName = &""
@export var inactive_prompt_prefix: String = "Activate"
@export var active_prompt_prefix: String = "Use"

@onready var interactable: InteractableComponent = $Interactable
@onready var visual: Sprite2D = get_node_or_null(^"Visual") as Sprite2D

var _definition: WaymarkDefinition = null
var _active: bool = false

func _ready() -> void:
    add_to_group(&"waymark_point")
    _definition = ContentDB.get_definition(waymark_definition_id) as WaymarkDefinition
    if _definition == null:
        push_error("WaymarkPoint2D could not resolve definition: %s" % String(waymark_definition_id))
        interactable.enabled = false
        return
    interactable.action_name = InteractionActions.ACTIVATE_WAYMARK
    if not interactable.interaction_requested.is_connected(_on_interaction_requested):
        interactable.interaction_requested.connect(_on_interaction_requested)
    if not WorldStateService.world_state_changed.is_connected(_on_world_state_changed):
        WorldStateService.world_state_changed.connect(_on_world_state_changed)
    _refresh_activation_state()

func _exit_tree() -> void:
    if WorldStateService.world_state_changed.is_connected(_on_world_state_changed):
        WorldStateService.world_state_changed.disconnect(_on_world_state_changed)

func get_definition() -> WaymarkDefinition:
    return _definition

func is_activated() -> bool:
    return _active

func validate_waymark_point() -> PackedStringArray:
    var errors: PackedStringArray = PackedStringArray()
    if waymark_definition_id == &"":
        errors.append("WaymarkPoint2D is missing waymark_definition_id")
    elif not String(waymark_definition_id).begins_with("waymark."):
        errors.append("WaymarkPoint2D definition should use waymark.* stable ID: %s" % String(waymark_definition_id))
    return errors

func _on_interaction_requested(_action: StringName, interactor: Node) -> void:
    if _definition == null:
        return
    if not _active:
        WorldStateService.set_flag(_definition.activation_state_key, true)
        QuestService.notify_event(QuestObjectiveDefinition.Kind.ACTIVATE_WAYMARK, _definition.content_id, 1)
        waymark_activated.emit(_definition.content_id)
        return
    travel_menu_requested.emit(_definition.content_id, interactor)

func _on_world_state_changed(key: StringName, _value: Variant) -> void:
    if _definition == null or key != _definition.activation_state_key:
        return
    _refresh_activation_state()

func _refresh_activation_state() -> void:
    if _definition == null:
        return
    var new_active: bool = WorldStateService.get_flag(_definition.activation_state_key, false)
    var changed: bool = new_active != _active
    _active = new_active
    if _active:
        interactable.prompt_text = "%s %s" % [active_prompt_prefix, _definition.display_name]
    else:
        interactable.prompt_text = "%s %s" % [inactive_prompt_prefix, _definition.display_name]
    if visual != null:
        visual.modulate = Color.WHITE if _active else Color("8b968b")
    if changed:
        activation_changed.emit(_definition.content_id, _active)

