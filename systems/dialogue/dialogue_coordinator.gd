extends Node
class_name DialogueCoordinator

signal dialogue_started(npc_id: StringName, dialogue_id: StringName)
signal dialogue_finished(npc_id: StringName, dialogue_id: StringName)

var _runner: DialogueRunner = null
var _panel: DialoguePanel = null
var _current_dialogue_id: StringName = &""

func _ready() -> void:
    add_to_group(&"dialogue_coordinator")
    call_deferred("_bind_world")

func start_dialogue(npc_id: StringName, dialogue_id: StringName) -> bool:
    var npc_definition: NPCDefinition = ContentDB.get_definition(npc_id) as NPCDefinition
    var definition: DialogueDefinition = ContentDB.get_definition(dialogue_id) as DialogueDefinition
    if definition == null:
        push_warning("DialogueCoordinator: unknown dialogue %s" % String(dialogue_id))
        return false
    if _panel == null or not is_instance_valid(_panel):
        _resolve_panel()
    if _panel == null:
        push_warning("DialogueCoordinator: no DialoguePanel available")
        return false
    _runner = DialogueRunner.new()
    var speaker: String = npc_definition.display_name if npc_definition != null else "Resident"
    if not _runner.begin(definition, npc_id, speaker):
        push_warning("DialogueCoordinator: dialogue %s has no available node" % String(dialogue_id))
        return false
    _current_dialogue_id = dialogue_id
    if npc_id != &"":
        QuestService.notify_talked_to_npc(npc_id)
    _panel.open_dialogue(
        _runner.get_speaker(),
        _runner.get_text(),
        _runner.get_available_choices(),
        _get_current_portrait(),
        _runner.get_role()
    )
    dialogue_started.emit(npc_id, dialogue_id)
    return true

func _bind_world() -> void:
    _resolve_panel()
    var region_root: RegionRoot = get_tree().get_first_node_in_group(&"region_root") as RegionRoot
    if region_root != null:
        var npcs: Node = region_root.get_node_or_null(^"NPCs")
        if npcs != null:
            for child: Node in npcs.get_children():
                if child is NPCActor:
                    _bind_npc(child as NPCActor)
    for node: Node in get_tree().get_nodes_in_group(&"npc_actor"):
        if node is NPCActor:
            _bind_npc(node as NPCActor)
    if not get_tree().node_added.is_connected(_on_node_added):
        get_tree().node_added.connect(_on_node_added)

func _exit_tree() -> void:
    if get_tree() != null and get_tree().node_added.is_connected(_on_node_added):
        get_tree().node_added.disconnect(_on_node_added)
    _disconnect_panel()

func _resolve_panel() -> void:
    _disconnect_panel()
    var region_root: RegionRoot = get_tree().get_first_node_in_group(&"region_root") as RegionRoot
    if region_root != null:
        var hud: CoreHUD = region_root.get_node_or_null(^"CoreHUD") as CoreHUD
        if hud != null:
            _panel = hud.dialogue_panel
    if _panel == null:
        for node: Node in get_tree().get_nodes_in_group(&"dialogue_panel"):
            if node is DialoguePanel:
                _panel = node as DialoguePanel
                break
    if _panel != null:
        if not _panel.advance_requested.is_connected(_on_advance_requested):
            _panel.advance_requested.connect(_on_advance_requested)
        if not _panel.choice_requested.is_connected(_on_choice_requested):
            _panel.choice_requested.connect(_on_choice_requested)
        if not _panel.close_requested.is_connected(_finish_dialogue):
            _panel.close_requested.connect(_finish_dialogue)

func _disconnect_panel() -> void:
    if _panel == null or not is_instance_valid(_panel):
        _panel = null
        return
    if _panel.advance_requested.is_connected(_on_advance_requested):
        _panel.advance_requested.disconnect(_on_advance_requested)
    if _panel.choice_requested.is_connected(_on_choice_requested):
        _panel.choice_requested.disconnect(_on_choice_requested)
    if _panel.close_requested.is_connected(_finish_dialogue):
        _panel.close_requested.disconnect(_finish_dialogue)
    _panel = null

func _bind_npc(npc: NPCActor) -> void:
    if npc != null and not npc.dialogue_requested.is_connected(_on_npc_dialogue_requested):
        npc.dialogue_requested.connect(_on_npc_dialogue_requested)

func _on_node_added(node: Node) -> void:
    if node is NPCActor:
        call_deferred("_bind_npc", node as NPCActor)

func _on_npc_dialogue_requested(npc_id: StringName, dialogue_id: StringName) -> void:
    start_dialogue(npc_id, dialogue_id)

func _on_advance_requested() -> void:
    _advance(-1)

func _on_choice_requested(choice_index: int) -> void:
    _advance(choice_index)

func _advance(choice_index: int) -> void:
    if _runner == null:
        return
    if not _runner.advance(choice_index):
        _finish_dialogue()
        return
    if _panel != null:
        _panel.show_node(
            _runner.get_speaker(),
            _runner.get_text(),
            _runner.get_available_choices(),
            _get_current_portrait(),
            _runner.get_role()
        )

func _get_current_portrait() -> Texture2D:
    if _runner == null or not _runner.should_show_portrait():
        return null
    var definition: NPCDefinition = ContentDB.get_definition(_runner.get_speaker_npc_id()) as NPCDefinition
    if definition == null:
        return null
    return definition.portrait_texture if definition.portrait_texture != null else definition.world_texture

func _finish_dialogue() -> void:
    if _runner == null:
        if _panel != null:
            _panel.close_dialogue()
        return
    var npc_id: StringName = _runner.npc_id
    var dialogue_id: StringName = _current_dialogue_id
    _runner = null
    _current_dialogue_id = &""
    if _panel != null:
        _panel.close_dialogue()
    dialogue_finished.emit(npc_id, dialogue_id)
