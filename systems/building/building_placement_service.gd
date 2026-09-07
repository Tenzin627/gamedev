extends RefCounted
class_name BuildingPlacementService

static func can_afford(definition: BuildingDefinition, inventory: InventoryComponent) -> bool:
    if definition == null or inventory == null:
        return false
    for cost: BuildCostEntry in definition.costs:
        if cost == null or not CarriedInventoryService.has_item(inventory, cost.item_id, cost.amount):
            return false
    return true

static func consume_cost(definition: BuildingDefinition, inventory: InventoryComponent) -> bool:
    if not can_afford(definition, inventory):
        return false
    var transaction_state: Dictionary = CarriedInventoryService.export_state(inventory)
    for cost: BuildCostEntry in definition.costs:
        if cost != null and CarriedInventoryService.remove_item(inventory, cost.item_id, cost.amount) > 0:
            CarriedInventoryService.restore_state(inventory, transaction_state)
            return false
    return true

static func cost_text(definition: BuildingDefinition, inventory: InventoryComponent = null) -> String:
    if definition == null or definition.costs.is_empty():
        return "Free"
    var parts: PackedStringArray = PackedStringArray()
    for cost: BuildCostEntry in definition.costs:
        if cost == null:
            continue
        var item: ItemDefinition = ContentDB.get_definition(cost.item_id) as ItemDefinition
        var owned: int = CarriedInventoryService.get_total_quantity(inventory, cost.item_id) if inventory != null else 0
        var label: String = item.display_name if item != null else String(cost.item_id)
        parts.append("%s %d/%d" % [label, owned, cost.amount])
    return "  •  ".join(parts)
