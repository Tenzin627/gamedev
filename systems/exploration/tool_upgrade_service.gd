extends RefCounted
class_name ToolUpgradeService

func can_upgrade(definition: ToolUpgradeDefinition, inventory: ItemSlotContainerComponent, hotbar: ItemSlotContainerComponent = null) -> Dictionary:
    if definition == null or inventory == null:
        return {"ok": false, "reason": "invalid"}
    if definition.required_progression_tag != &"" and not PlayerProgressionService.has_unlock_tag(definition.required_progression_tag):
        return {"ok": false, "reason": "progression"}
    if _get_total_quantity(definition.from_tool_id, inventory, hotbar) <= 0:
        return {"ok": false, "reason": "missing_tool"}
    var currency: int = int(GameSession.get_value(&"currency", 0))
    if currency < definition.currency_cost:
        return {"ok": false, "reason": "currency"}
    for key: Variant in definition.material_costs.keys():
        var item_id: StringName = StringName(str(key))
        var amount: int = int(definition.material_costs[key])
        if _get_total_quantity(item_id, inventory, hotbar) < amount:
            return {"ok": false, "reason": "materials"}
    return {"ok": true, "reason": ""}

func perform_upgrade(definition: ToolUpgradeDefinition, inventory: ItemSlotContainerComponent, hotbar: ItemSlotContainerComponent = null) -> Dictionary:
    var check: Dictionary = can_upgrade(definition, inventory, hotbar)
    if not bool(check.get("ok", false)):
        return check

    var output_definition: ItemDefinition = ContentDB.get_definition(definition.to_tool_id) as ItemDefinition
    if output_definition == null:
        return {"ok": false, "reason": "invalid"}

    var source: Dictionary = _find_item_slot(definition.from_tool_id, hotbar)
    if source.is_empty():
        source = _find_item_slot(definition.from_tool_id, inventory)
    if source.is_empty():
        return {"ok": false, "reason": "missing_tool"}

    var inventory_state: Array = inventory.export_slots()
    var hotbar_state: Array = hotbar.export_slots() if hotbar != null else []

    for key: Variant in definition.material_costs.keys():
        var item_id: StringName = StringName(str(key))
        var amount: int = int(definition.material_costs[key])
        if _remove_across(item_id, amount, inventory, hotbar) > 0:
            inventory.import_slots(inventory_state, inventory.get_slot_count())
            if hotbar != null:
                hotbar.import_slots(hotbar_state, hotbar.get_slot_count())
            return {"ok": false, "reason": "materials"}

    var source_container: ItemSlotContainerComponent = source.get("container") as ItemSlotContainerComponent
    var source_slot: int = int(source.get("slot", -1))
    if source_container == null or source_slot < 0:
        return {"ok": false, "reason": "missing_tool"}

    # Tools are single-stack items. Replacing the source slot preserves the hotbar
    # position when the Field Axe/Pickaxe is upgraded from the quick bar.
    if not source_container.replace_stack_at(source_slot, ItemStack.new(definition.to_tool_id, 1)):
        inventory.import_slots(inventory_state, inventory.get_slot_count())
        if hotbar != null:
            hotbar.import_slots(hotbar_state, hotbar.get_slot_count())
        return {"ok": false, "reason": "inventory_full"}

    var currency: int = int(GameSession.get_value(&"currency", 0))
    GameSession.set_value(&"currency", currency - definition.currency_cost)
    return {"ok": true, "reason": "", "item_id": definition.to_tool_id}

func _get_total_quantity(item_id: StringName, first: ItemSlotContainerComponent, second: ItemSlotContainerComponent) -> int:
    var total: int = first.get_total_quantity(item_id) if first != null else 0
    if second != null and second != first:
        total += second.get_total_quantity(item_id)
    return total

func _remove_across(item_id: StringName, amount: int, first: ItemSlotContainerComponent, second: ItemSlotContainerComponent) -> int:
    var remaining: int = maxi(amount, 0)
    if remaining <= 0:
        return 0
    if first != null:
        remaining = first.remove_item(item_id, remaining)
    if remaining > 0 and second != null and second != first:
        remaining = second.remove_item(item_id, remaining)
    return remaining

func _find_item_slot(item_id: StringName, container: ItemSlotContainerComponent) -> Dictionary:
    if container == null:
        return {}
    for i: int in range(container.get_slot_count()):
        if container.get_item_id(i) == item_id:
            return {"container": container, "slot": i}
    return {}
