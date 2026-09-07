extends RefCounted
class_name ContentConditionEvaluator

static func evaluate(condition: ContentCondition) -> bool:
    if condition == null:
        return true
    var result: bool = false
    match condition.kind:
        ContentCondition.Kind.ALWAYS:
            result = true
        ContentCondition.Kind.WORLD_FLAG:
            result = WorldStateService.get_flag(condition.key, false) == _as_bool(condition.expected_value)
        ContentCondition.Kind.QUEST_STATUS:
            result = QuestService.get_quest_status(condition.key) == condition.expected_value
        ContentCondition.Kind.INVENTORY_ITEM:
            result = _compare_int(_get_inventory_quantity(condition.key), maxi(condition.amount, 1), condition.comparison)
        ContentCondition.Kind.SESSION_VALUE:
            result = str(GameSession.get_value(condition.key, "")) == condition.expected_value
        ContentCondition.Kind.CURRENCY:
            result = _compare_int(int(GameSession.get_value(&"currency", 0)), condition.amount, condition.comparison)
        ContentCondition.Kind.CREATURE_OWNED:
            result = _compare_int(_get_owned_species_count(condition.key), maxi(condition.amount, 1), condition.comparison)
        ContentCondition.Kind.WAYMARK_ACTIVE:
            result = _is_waymark_active(condition.key)
        ContentCondition.Kind.RECIPE_DISCOVERED:
            result = _is_recipe_discovered(condition.key)
        ContentCondition.Kind.BUILDING_PLACED:
            result = _compare_int(_get_placed_building_count(condition.key), maxi(condition.amount, 1), condition.comparison)
        ContentCondition.Kind.DISCOVERY_FOUND:
            result = _is_discovery_found(condition.key)
        ContentCondition.Kind.CURRENT_ZONE:
            result = SceneRouter.current_zone_id == condition.key
    return not result if condition.inverted else result

static func evaluate_all(conditions: Array) -> bool:
    for resource: Resource in conditions:
        var condition: ContentCondition = resource as ContentCondition
        if condition != null and not evaluate(condition):
            return false
    return true

static func _get_inventory_quantity(item_id: StringName) -> int:
    return _get_saved_container_quantity(&"inventory_slots", item_id) + _get_saved_container_quantity(&"hotbar", item_id)

static func _get_saved_container_quantity(state_key: StringName, item_id: StringName) -> int:
    var container_variant: Variant = GameSession.get_value(state_key, {})
    if not container_variant is Dictionary:
        return 0
    var slots_variant: Variant = Dictionary(container_variant).get("slots", [])
    if not slots_variant is Array:
        return 0
    var total: int = 0
    for slot_variant: Variant in Array(slots_variant):
        if not slot_variant is Dictionary:
            continue
        var slot: Dictionary = Dictionary(slot_variant)
        if StringName(str(slot.get("item_id", ""))) == item_id:
            total += int(slot.get("quantity", 0))
    return total

static func _get_owned_species_count(species_id: StringName) -> int:
    var total: int = 0
    for entry_variant: Variant in GameSession.creature_instances:
        if not entry_variant is Dictionary:
            continue
        if StringName(str(Dictionary(entry_variant).get("species_id", ""))) == species_id:
            total += 1
    return total

static func _is_waymark_active(waymark_id: StringName) -> bool:
    if waymark_id == &"":
        return false
    if WorldStateService.get_flag(StringName("waymark.%s.active" % String(waymark_id)), false):
        return true
    var active_variant: Variant = GameSession.get_value(&"active_waymarks", [])
    if active_variant is Array:
        for entry: Variant in Array(active_variant):
            if StringName(str(entry)) == waymark_id:
                return true
    return false

static func _is_recipe_discovered(recipe_id: StringName) -> bool:
    var discovered_variant: Variant = GameSession.get_value(&"discovered_recipes", [])
    if discovered_variant is Array:
        for entry: Variant in Array(discovered_variant):
            if StringName(str(entry)) == recipe_id:
                return true
    var definition: RecipeDefinition = ContentDB.get_definition(recipe_id) as RecipeDefinition
    return definition != null and definition.discovered_by_default

static func _is_discovery_found(discovery_id: StringName) -> bool:
    var discovered_variant: Variant = GameSession.get_value(&"exploration_discoveries", [])
    if discovered_variant is Array:
        return Array(discovered_variant).has(String(discovery_id))
    return false

static func _get_placed_building_count(building_id: StringName) -> int:
    var total: int = 0
    var runtime_variant: Variant = GameSession.get_value(&"region_runtime", {})
    if not runtime_variant is Dictionary:
        return 0
    for zone_variant: Variant in Dictionary(runtime_variant).values():
        if not zone_variant is Dictionary:
            continue
        var zone: Dictionary = Dictionary(zone_variant)
        var buildings_variant: Variant = zone.get("placed_buildings", [])
        if not buildings_variant is Array:
            continue
        for building_variant: Variant in Array(buildings_variant):
            if not building_variant is Dictionary:
                continue
            if StringName(str(Dictionary(building_variant).get("building_id", ""))) == building_id:
                total += 1
    return total

static func _compare_int(current: int, expected: int, comparison: ContentCondition.Compare) -> bool:
    match comparison:
        ContentCondition.Compare.EQUAL:
            return current == expected
        ContentCondition.Compare.NOT_EQUAL:
            return current != expected
        ContentCondition.Compare.AT_LEAST:
            return current >= expected
        ContentCondition.Compare.AT_MOST:
            return current <= expected
        ContentCondition.Compare.GREATER:
            return current > expected
        ContentCondition.Compare.LESS:
            return current < expected
    return false

static func _as_bool(value: String) -> bool:
    var normalized: String = value.strip_edges().to_lower()
    return normalized == "true" or normalized == "1" or normalized == "yes"
