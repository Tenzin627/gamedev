extends RefCounted
class_name ContentActionExecutor

static func execute_all(actions: Array) -> void:
    for resource: Resource in actions:
        var action: ContentAction = resource as ContentAction
        if action != null:
            execute(action)

static func execute(action: ContentAction) -> void:
    if action == null:
        return
    match action.kind:
        ContentAction.Kind.SET_WORLD_FLAG:
            WorldStateService.set_flag(action.key, _as_bool(action.value))
        ContentAction.Kind.ACCEPT_QUEST:
            QuestService.accept_quest(action.key)
        ContentAction.Kind.COMPLETE_QUEST:
            QuestService.complete_quest(action.key)
        ContentAction.Kind.ADD_CURRENCY:
            var current: int = int(GameSession.get_value(&"currency", 0))
            GameSession.set_value(&"currency", current + action.amount)
        ContentAction.Kind.SET_SESSION_VALUE:
            GameSession.set_value(action.key, _parse_value(action.value))
        ContentAction.Kind.DISCOVER_RECIPE:
            CraftingService.discover(action.key)
        ContentAction.Kind.ACTIVATE_WAYMARK:
            WorldStateService.set_flag(StringName("waymark.%s.active" % String(action.key)), true)
            _add_unique_session_id(&"active_waymarks", action.key)
            QuestService.notify_event(QuestObjectiveDefinition.Kind.ACTIVATE_WAYMARK, action.key, 1)
        ContentAction.Kind.DISCOVER_CONTENT:
            var discovery: ExplorationProgressService = ExplorationProgressService.new()
            discovery.discover(action.key)
            discovery.free()
        ContentAction.Kind.ADD_ITEM:
            _change_carried_item(action.key, maxi(action.amount, 1))
        ContentAction.Kind.REMOVE_ITEM:
            _change_carried_item(action.key, -maxi(action.amount, 1))

static func _change_carried_item(item_id: StringName, delta: int) -> void:
    if item_id == &"" or delta == 0:
        return
    var player: PlayerActor = null
    if Engine.get_main_loop() is SceneTree:
        player = (Engine.get_main_loop() as SceneTree).get_first_node_in_group(&"player") as PlayerActor
    if player == null:
        push_warning("ContentActionExecutor could not deliver %s because no player is loaded" % String(item_id))
        return
    if delta > 0:
        var remaining: int = CarriedInventoryService.add_item(player.inventory_component, item_id, delta, player.hotbar_component)
        if remaining > 0:
            remaining = _store_reward_overflow(item_id, remaining)
        if remaining > 0:
            _queue_reward(item_id, remaining)
        return
    CarriedInventoryService.remove_item(player.inventory_component, item_id, -delta, player.hotbar_component)

static func _store_reward_overflow(item_id: StringName, amount: int) -> int:
    var region: RegionRoot = SceneRouter.get_current_region_root()
    if region == null:
        return amount
    var farm_storage: FarmStorageSystem = region.get_local_system(&"FarmStorageSystem") as FarmStorageSystem
    if farm_storage == null or farm_storage.storage == null:
        return amount
    return farm_storage.storage.add_item(item_id, amount)

static func _queue_reward(item_id: StringName, amount: int) -> void:
    if item_id == &"" or amount <= 0:
        return
    var pending: Array = Array(GameSession.get_value(&"pending_item_rewards", [])).duplicate(true)
    pending.append({"item_id": String(item_id), "amount": amount})
    GameSession.set_value(&"pending_item_rewards", pending)

static func claim_pending_rewards(player: PlayerActor) -> int:
    if player == null:
        return 0
    var pending: Array = Array(GameSession.get_value(&"pending_item_rewards", [])).duplicate(true)
    var remaining_entries: Array = []
    var delivered: int = 0
    for entry_variant: Variant in pending:
        if not entry_variant is Dictionary:
            continue
        var entry: Dictionary = Dictionary(entry_variant)
        var item_id: StringName = StringName(str(entry.get("item_id", "")))
        var amount: int = maxi(int(entry.get("amount", 0)), 0)
        var remaining: int = CarriedInventoryService.add_item(player.inventory_component, item_id, amount, player.hotbar_component)
        if remaining > 0:
            remaining = _store_reward_overflow(item_id, remaining)
        delivered += amount - remaining
        if remaining > 0:
            remaining_entries.append({"item_id": String(item_id), "amount": remaining})
    GameSession.set_value(&"pending_item_rewards", remaining_entries)
    return delivered

static func _add_unique_session_id(state_key: StringName, content_id: StringName) -> void:
    if content_id == &"":
        return
    var stored: Variant = GameSession.get_value(state_key, [])
    var values: Array = Array(stored).duplicate() if stored is Array else []
    var text_id: String = String(content_id)
    if not values.has(text_id):
        values.append(text_id)
        GameSession.set_value(state_key, values)

static func _parse_value(value: String) -> Variant:
    var normalized: String = value.strip_edges().to_lower()
    if normalized == "true":
        return true
    if normalized == "false":
        return false
    if value.is_valid_int():
        return value.to_int()
    if value.is_valid_float():
        return value.to_float()
    return value

static func _as_bool(value: String) -> bool:
    var normalized: String = value.strip_edges().to_lower()
    return normalized == "true" or normalized == "1" or normalized == "yes"
