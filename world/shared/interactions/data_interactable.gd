extends Node2D
class_name DataInteractable

@export var interaction_definition_id: StringName = &""
@export var draw_debug_marker: bool = false
@onready var interactable: InteractableComponent = $Interactable

var _definition: InteractionDefinition = null

func _ready() -> void:
    _definition = ContentDB.get_definition(interaction_definition_id) as InteractionDefinition
    if _definition == null:
        push_error("DataInteractable could not resolve %s" % String(interaction_definition_id))
        interactable.enabled = false
        return
    interactable.action_name = _definition.action_name
    interactable.interaction_requested.connect(_on_interaction_requested)
    if not WorldStateService.world_state_changed.is_connected(_on_context_changed):
        WorldStateService.world_state_changed.connect(_on_context_changed)
    if not GameSession.session_state_changed.is_connected(_on_session_changed):
        GameSession.session_state_changed.connect(_on_session_changed)
    _refresh()

func _exit_tree() -> void:
    if WorldStateService.world_state_changed.is_connected(_on_context_changed):
        WorldStateService.world_state_changed.disconnect(_on_context_changed)
    if GameSession.session_state_changed.is_connected(_on_session_changed):
        GameSession.session_state_changed.disconnect(_on_session_changed)

func _on_interaction_requested(_action: StringName, _interactor: Node) -> void:
    if _definition == null:
        return
    var state: InteractionStateDefinition = _definition.get_matching_state()
    if state == null:
        _show_status(_definition.fallback_feedback)
        return
    ContentActionExecutor.execute_all(state.actions)
    var event_target: StringName = state.quest_event_target_id if state.quest_event_target_id != &"" else _definition.content_id
    QuestService.notify_event(QuestObjectiveDefinition.Kind.INTERACT_WITH, event_target, state.quest_event_amount)
    if not state.feedback_text.strip_edges().is_empty():
        _show_status(state.feedback_text)
    _refresh()

func _refresh() -> void:
    if _definition == null or interactable == null:
        return
    var state: InteractionStateDefinition = _definition.get_matching_state()
    interactable.prompt_text = state.prompt_text if state != null else _definition.fallback_prompt
    queue_redraw()

func _show_status(message: String, seconds: float = 2.8) -> void:
    if message.strip_edges().is_empty():
        return
    var root: RegionRoot = get_tree().get_first_node_in_group(&"region_root") as RegionRoot
    if root == null:
        return
    var hud: CoreHUD = root.get_node_or_null(^"CoreHUD") as CoreHUD
    if hud != null:
        hud.show_status_message(message, seconds)

func _on_context_changed(_key: StringName, _value: Variant) -> void:
    _refresh()

func _on_session_changed(_key: StringName, _value: Variant) -> void:
    _refresh()

func _draw() -> void:
    if draw_debug_marker:
        draw_circle(Vector2.ZERO, 12.0, Color(0.65, 0.85, 0.7, 0.7))
