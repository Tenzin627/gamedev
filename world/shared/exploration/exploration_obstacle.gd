extends Node2D
class_name ExplorationObstacle

@export var obstacle_definition_id: StringName = &""
@export var visual_size: Vector2 = Vector2(90, 38)

var _definition: ExplorationObstacleDefinition = null
var _interactable: InteractableComponent = null
var _tool_target: ToolTargetComponent = null
var _visual: Sprite2D = null

func _ready() -> void:
    _definition = ContentDB.get_definition(obstacle_definition_id) as ExplorationObstacleDefinition
    _interactable = get_node_or_null(^"Interactable") as InteractableComponent
    _tool_target = get_node_or_null(^"ToolTarget") as ToolTargetComponent
    _visual = get_node_or_null(^"Visual") as Sprite2D
    if _interactable != null:
        _interactable.interaction_requested.connect(_on_interaction)
    if _tool_target != null and _definition != null:
        _tool_target.accepted_tool_tags = PackedStringArray([String(_definition.required_tool_tag)]) if _definition.required_tool_tag != &"" else PackedStringArray()
        _tool_target.minimum_tool_tier = _definition.minimum_tool_tier
        if not _tool_target.tool_applied.is_connected(_on_tool_applied):
            _tool_target.tool_applied.connect(_on_tool_applied)
    if WorldStateService.world_state_changed.is_connected(_on_world_state_changed) == false:
        WorldStateService.world_state_changed.connect(_on_world_state_changed)
    _refresh()


func _on_interaction(_action: StringName, interactor: Node) -> void:
    if _definition == null or WorldStateService.get_flag(_definition.completion_world_flag, false):
        return
    if _definition.required_world_flag != &"" and not WorldStateService.get_flag(_definition.required_world_flag, false):
        _show_status("The route cannot be cleared yet.")
        return

    var player: PlayerActor = _resolve_player(interactor)
    if player == null:
        return
    if _definition.required_tool_tag != &"" and _find_owned_valid_tool(player) == null:
        _show_status("Requires a %s tool at tier %d or higher." % [_format_tool_tag(_definition.required_tool_tag), _definition.minimum_tool_tier], 3.5)
        return
    _clear_obstacle()

func _on_tool_applied(tool: ToolDefinition, _inventory: InventoryComponent, _source: Node) -> void:
    if _definition == null or tool == null:
        return
    if _definition.required_tool_tag != &"" and tool.tool_tag != _definition.required_tool_tag:
        return
    if tool.tool_tier < _definition.minimum_tool_tier:
        _show_status("%s is too weak. This obstacle requires tier %d or higher." % [tool.display_name, _definition.minimum_tool_tier], 3.0)
        return
    _clear_obstacle()

func _clear_obstacle() -> void:
    if _definition == null or WorldStateService.get_flag(_definition.completion_world_flag, false):
        return
    WorldStateService.set_flag(_definition.completion_world_flag, true)
    _show_status("%s cleared." % _definition.display_name, 2.8)
    _refresh()

func _format_tool_tag(tool_tag: StringName) -> String:
    var text: String = String(tool_tag).replace("_", " ").strip_edges()
    return text.capitalize() if not text.is_empty() else "required"

func _find_owned_valid_tool(player: PlayerActor) -> ToolDefinition:
    if player == null or _definition == null:
        return null
    var containers: Array[ItemSlotContainerComponent] = [player.hotbar_component, player.inventory_component]
    for container: ItemSlotContainerComponent in containers:
        if container == null:
            continue
        for i: int in range(container.get_slot_count()):
            var item_id: StringName = container.get_item_id(i)
            if item_id == &"":
                continue
            var tool: ToolDefinition = ContentDB.get_definition(item_id) as ToolDefinition
            if tool != null and tool.tool_tag == _definition.required_tool_tag and tool.tool_tier >= _definition.minimum_tool_tier:
                return tool
    return null

func _resolve_player(interactor: Node) -> PlayerActor:
    var player: PlayerActor = interactor as PlayerActor
    if player != null:
        return player
    if interactor != null:
        player = interactor.get_parent() as PlayerActor
    return player

func _show_status(message: String, seconds: float = 2.5) -> void:
    var root: RegionRoot = get_tree().get_first_node_in_group(&"region_root") as RegionRoot
    if root == null:
        return
    var hud: CoreHUD = root.get_node_or_null(^"CoreHUD") as CoreHUD
    if hud != null:
        hud.show_status_message(message, seconds)

func _on_world_state_changed(key: StringName, _value: Variant) -> void:
    if _definition != null and key == _definition.completion_world_flag:
        _refresh()

func _refresh() -> void:
    if _definition == null:
        return
    var cleared: bool = WorldStateService.get_flag(_definition.completion_world_flag, false)
    if _interactable != null:
        _interactable.enabled = not cleared
        _interactable.prompt_text = _definition.clear_prompt if not cleared else _definition.blocked_prompt
    if _tool_target != null:
        _tool_target.enabled = not cleared
    if _visual != null:
        _visual.visible = not cleared
    var body: StaticBody2D = get_node_or_null(^"Blocker") as StaticBody2D
    if body != null:
        body.process_mode = Node.PROCESS_MODE_DISABLED if cleared else Node.PROCESS_MODE_INHERIT
