extends RefCounted
class_name CarriedInventoryService

static func get_hotbar(inventory: InventoryComponent, explicit_hotbar: HotbarComponent = null) -> HotbarComponent:
    if explicit_hotbar != null:
        return explicit_hotbar
    if inventory == null or inventory.get_parent() == null:
        return null
    return inventory.get_parent().get_node_or_null(^"HotbarComponent") as HotbarComponent

static func get_total_quantity(inventory: InventoryComponent, item_id: StringName, hotbar: HotbarComponent = null) -> int:
    if inventory == null:
        return 0
    var total: int = inventory.get_total_quantity(item_id)
    var resolved_hotbar: HotbarComponent = get_hotbar(inventory, hotbar)
    if resolved_hotbar != null:
        total += resolved_hotbar.get_total_quantity(item_id)
    return total

static func has_item(inventory: InventoryComponent, item_id: StringName, amount: int = 1, hotbar: HotbarComponent = null) -> bool:
    return amount <= 0 or get_total_quantity(inventory, item_id, hotbar) >= amount

static func get_item_ids(inventory: InventoryComponent, hotbar: HotbarComponent = null) -> Array[StringName]:
    var result: Array[StringName] = []
    var containers: Array[ItemSlotContainerComponent] = []
    if inventory != null:
        containers.append(inventory)
    var resolved_hotbar: HotbarComponent = get_hotbar(inventory, hotbar)
    if resolved_hotbar != null:
        containers.append(resolved_hotbar)
    for container: ItemSlotContainerComponent in containers:
        for i: int in range(container.get_slot_count()):
            var item_id: StringName = container.get_item_id(i)
            if item_id != &"" and not result.has(item_id):
                result.append(item_id)
    return result

static func remove_item(inventory: InventoryComponent, item_id: StringName, amount: int, hotbar: HotbarComponent = null) -> int:
    if inventory == null or amount <= 0:
        return maxi(amount, 0)
    var remaining: int = inventory.remove_item(item_id, amount)
    var resolved_hotbar: HotbarComponent = get_hotbar(inventory, hotbar)
    if remaining > 0 and resolved_hotbar != null:
        remaining = resolved_hotbar.remove_item(item_id, remaining)
    return remaining

static func add_item(inventory: InventoryComponent, item_id: StringName, amount: int, hotbar: HotbarComponent = null) -> int:
    if inventory == null or amount <= 0:
        return maxi(amount, 0)
    var remaining: int = inventory.add_item(item_id, amount)
    var resolved_hotbar: HotbarComponent = get_hotbar(inventory, hotbar)
    if remaining > 0 and resolved_hotbar != null:
        remaining = resolved_hotbar.add_item(item_id, remaining)
    return remaining

static func can_add_item(inventory: InventoryComponent, item_id: StringName, amount: int, hotbar: HotbarComponent = null) -> bool:
    if inventory == null or amount <= 0:
        return amount <= 0
    var definition: ItemDefinition = ContentDB.get_definition(item_id) as ItemDefinition
    if definition == null:
        return false
    var max_stack: int = maxi(definition.max_stack, 1)
    var capacity: int = 0
    var containers: Array[ItemSlotContainerComponent] = [inventory]
    var resolved_hotbar: HotbarComponent = get_hotbar(inventory, hotbar)
    if resolved_hotbar != null:
        containers.append(resolved_hotbar)
    for container: ItemSlotContainerComponent in containers:
        for i: int in range(container.get_slot_count()):
            var stack: ItemStack = container.get_stack_at(i)
            if stack == null or stack.is_empty():
                capacity += max_stack
            elif stack.item_id == item_id:
                capacity += maxi(max_stack - stack.quantity, 0)
            if capacity >= amount:
                return true
    return false

static func export_state(inventory: InventoryComponent, hotbar: HotbarComponent = null) -> Dictionary:
    var resolved_hotbar: HotbarComponent = get_hotbar(inventory, hotbar)
    return {
        "inventory": inventory.export_state() if inventory != null else {},
        "hotbar": resolved_hotbar.export_state() if resolved_hotbar != null else {},
    }

static func restore_state(inventory: InventoryComponent, state: Dictionary, hotbar: HotbarComponent = null) -> void:
    if inventory != null:
        inventory.import_state(Dictionary(state.get("inventory", {})), false)
    var resolved_hotbar: HotbarComponent = get_hotbar(inventory, hotbar)
    if resolved_hotbar != null:
        resolved_hotbar.import_state(Dictionary(state.get("hotbar", {})), false)
