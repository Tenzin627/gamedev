extends Node
class_name ItemSlotContainerComponent

signal container_changed
signal slot_changed(slot_index: int, stack: ItemStack)
signal item_added(item_id: StringName, amount: int, total_quantity: int)
signal item_removed(item_id: StringName, amount: int, total_quantity: int)
signal items_transferred(source_index: int, target_container: ItemSlotContainerComponent, target_index: int, item_id: StringName, amount: int)

var _slots: Array = []

func configure_slots(slot_count: int) -> void:
    _resize_slots(maxi(slot_count, 1))

func get_slot_count() -> int:
    return _slots.size()

func get_stack_at(slot_index: int) -> ItemStack:
    if not is_valid_slot(slot_index):
        return null
    var stack_value: Variant = _slots[slot_index]
    return stack_value as ItemStack

func get_stack_copy(slot_index: int) -> ItemStack:
    var stack: ItemStack = get_stack_at(slot_index)
    return stack.duplicate_stack() if stack != null else null

func get_item_id(slot_index: int) -> StringName:
    var stack: ItemStack = get_stack_at(slot_index)
    if stack == null or stack.is_empty():
        return &""
    return stack.item_id

func get_quantity_at(slot_index: int) -> int:
    var stack: ItemStack = get_stack_at(slot_index)
    return stack.quantity if stack != null and not stack.is_empty() else 0

func get_total_quantity(item_id: StringName) -> int:
    var total: int = 0
    for stack_value: Variant in _slots:
        var stack: ItemStack = stack_value as ItemStack
        if stack != null and not stack.is_empty() and stack.item_id == item_id:
            total += stack.quantity
    return total

func has_item(item_id: StringName, quantity: int = 1) -> bool:
    return quantity <= 0 or get_total_quantity(item_id) >= quantity

func is_valid_slot(slot_index: int) -> bool:
    return slot_index >= 0 and slot_index < _slots.size()

func can_place_stack(slot_index: int, stack: ItemStack) -> bool:
    if not is_valid_slot(slot_index):
        return false
    if stack == null or stack.is_empty():
        return true
    var definition: ItemDefinition = _get_item_definition(stack.item_id)
    if definition == null:
        return false
    return stack.quantity > 0 and stack.quantity <= maxi(definition.max_stack, 1)

func replace_stack_at(slot_index: int, stack: ItemStack) -> bool:
    if not is_valid_slot(slot_index) or not can_place_stack(slot_index, stack):
        return false
    _slots[slot_index] = stack.duplicate_stack() if stack != null and not stack.is_empty() else null
    _emit_slot_changed(slot_index)
    _emit_container_changed()
    return true

func clear_slot(slot_index: int) -> bool:
    if not is_valid_slot(slot_index):
        return false
    if get_stack_at(slot_index) == null:
        return true
    _slots[slot_index] = null
    _emit_slot_changed(slot_index)
    _emit_container_changed()
    return true

func clear_all_slots() -> void:
    var changed: bool = false
    for i: int in range(_slots.size()):
        if _slots[i] != null:
            _slots[i] = null
            _emit_slot_changed(i)
            changed = true
    if changed:
        _emit_container_changed()

func add_item(item_id: StringName, amount: int = 1) -> int:
    if amount <= 0:
        return 0
    var definition: ItemDefinition = _get_item_definition(item_id)
    if definition == null:
        push_warning("ItemSlotContainerComponent: refusing unknown/non-item content_id %s" % String(item_id))
        return amount

    var remaining: int = amount
    var max_stack: int = maxi(definition.max_stack, 1)
    var changed_indices: Array[int] = []

    for i: int in range(_slots.size()):
        var stack: ItemStack = get_stack_at(i)
        if stack == null or stack.is_empty() or stack.item_id != item_id or stack.quantity >= max_stack:
            continue
        var added: int = mini(remaining, max_stack - stack.quantity)
        stack.quantity += added
        remaining -= added
        changed_indices.append(i)
        if remaining <= 0:
            break

    if remaining > 0:
        for i: int in range(_slots.size()):
            var stack: ItemStack = get_stack_at(i)
            if stack != null and not stack.is_empty():
                continue
            var added: int = mini(remaining, max_stack)
            _slots[i] = ItemStack.new(item_id, added)
            remaining -= added
            changed_indices.append(i)
            if remaining <= 0:
                break

    var actually_added: int = amount - remaining
    if actually_added > 0:
        _emit_changed_indices(changed_indices)
        _emit_container_changed()
        item_added.emit(item_id, actually_added, get_total_quantity(item_id))
    return remaining

func remove_item(item_id: StringName, amount: int = 1) -> int:
    if amount <= 0:
        return 0
    var remaining: int = amount
    var changed_indices: Array[int] = []

    for offset: int in range(_slots.size()):
        var i: int = _slots.size() - 1 - offset
        var stack: ItemStack = get_stack_at(i)
        if stack == null or stack.is_empty() or stack.item_id != item_id:
            continue
        var removed: int = mini(remaining, stack.quantity)
        stack.quantity -= removed
        remaining -= removed
        if stack.quantity <= 0:
            _slots[i] = null
        changed_indices.append(i)
        if remaining <= 0:
            break

    var actually_removed: int = amount - remaining
    if actually_removed > 0:
        _emit_changed_indices(changed_indices)
        _emit_container_changed()
        item_removed.emit(item_id, actually_removed, get_total_quantity(item_id))
    return remaining

func can_add_batch(items: Dictionary) -> bool:
    if items.is_empty():
        return true

    var empty_slots: int = 0
    for stack_value: Variant in _slots:
        var stack: ItemStack = stack_value as ItemStack
        if stack == null or stack.is_empty():
            empty_slots += 1

    var required_new_slots: int = 0
    for key: Variant in items.keys():
        var item_id: StringName = StringName(str(key))
        var requested_amount: int = int(items.get(key, 0))
        if requested_amount <= 0:
            continue
        var definition: ItemDefinition = _get_item_definition(item_id)
        if definition == null:
            return false
        var max_stack: int = maxi(definition.max_stack, 1)
        var free_existing: int = 0
        for stack_value: Variant in _slots:
            var stack: ItemStack = stack_value as ItemStack
            if stack != null and not stack.is_empty() and stack.item_id == item_id:
                free_existing += maxi(max_stack - stack.quantity, 0)
        var remaining_after_existing: int = maxi(requested_amount - free_existing, 0)
        if remaining_after_existing > 0:
            required_new_slots += int(ceil(float(remaining_after_existing) / float(max_stack)))
            if required_new_slots > empty_slots:
                return false
    return required_new_slots <= empty_slots

func add_batch(items: Dictionary) -> Dictionary:
    var leftovers: Dictionary = {}
    if items.is_empty():
        return leftovers
    if not can_add_batch(items):
        return items.duplicate(true)
    for key: Variant in items.keys():
        var item_id: StringName = StringName(str(key))
        var requested_amount: int = int(items.get(key, 0))
        if requested_amount <= 0:
            continue
        var remaining: int = add_item(item_id, requested_amount)
        if remaining > 0:
            leftovers[item_id] = remaining
    return leftovers

func can_transfer_slot_to(from_index: int, target: ItemSlotContainerComponent, to_index: int) -> bool:
    if target == null or not is_valid_slot(from_index) or not target.is_valid_slot(to_index):
        return false
    if target == self and from_index == to_index:
        return false

    var source_stack: ItemStack = get_stack_at(from_index)
    if source_stack == null or source_stack.is_empty():
        return false
    var target_stack: ItemStack = target.get_stack_at(to_index)

    if target_stack == null or target_stack.is_empty():
        return target.can_place_stack(to_index, source_stack)

    if target_stack.item_id == source_stack.item_id:
        var definition: ItemDefinition = _get_item_definition(source_stack.item_id)
        if definition == null:
            return false
        return target_stack.quantity < maxi(definition.max_stack, 1)

    return target.can_place_stack(to_index, source_stack) and can_place_stack(from_index, target_stack)

func transfer_slot_to(from_index: int, target: ItemSlotContainerComponent, to_index: int) -> bool:
    if not can_transfer_slot_to(from_index, target, to_index):
        return false

    var source_stack: ItemStack = get_stack_copy(from_index)
    if source_stack == null:
        return false
    var target_stack: ItemStack = target.get_stack_copy(to_index)
    var transferred_item_id: StringName = source_stack.item_id
    var transferred_amount: int = source_stack.quantity

    if target_stack == null or target_stack.is_empty():
        _slots[from_index] = null
        target._slots[to_index] = source_stack
    elif target_stack.item_id == source_stack.item_id:
        var definition: ItemDefinition = _get_item_definition(source_stack.item_id)
        if definition == null:
            return false
        var max_stack: int = maxi(definition.max_stack, 1)
        var moved: int = mini(source_stack.quantity, max_stack - target_stack.quantity)
        if moved <= 0:
            return false
        source_stack.quantity -= moved
        target_stack.quantity += moved
        _slots[from_index] = source_stack if source_stack.quantity > 0 else null
        target._slots[to_index] = target_stack
        transferred_amount = moved
    else:
        _slots[from_index] = target_stack
        target._slots[to_index] = source_stack

    _emit_slot_changed(from_index)
    if target == self:
        _emit_slot_changed(to_index)
        _emit_container_changed()
    else:
        target._emit_slot_changed(to_index)
        _emit_container_changed()
        target._emit_container_changed()
    items_transferred.emit(from_index, target, to_index, transferred_item_id, transferred_amount)
    return true

func transfer_slot_to_first_available(from_index: int, target: ItemSlotContainerComponent) -> bool:
    if target == null or not is_valid_slot(from_index):
        return false
    var source_stack: ItemStack = get_stack_at(from_index)
    if source_stack == null or source_stack.is_empty():
        return false
    for i: int in range(target.get_slot_count()):
        if target.get_item_id(i) == source_stack.item_id and can_transfer_slot_to(from_index, target, i):
            return transfer_slot_to(from_index, target, i)
    for i: int in range(target.get_slot_count()):
        if target.get_stack_at(i) == null and can_transfer_slot_to(from_index, target, i):
            return transfer_slot_to(from_index, target, i)
    return false

# Transfers min(amount, source quantity) only when the target can accept that full capped amount.
# Returns false without mutating either container when total destination capacity is insufficient.
func transfer_amount_to_first_available(from_index: int, target: ItemSlotContainerComponent, amount: int) -> bool:
    if target == null or amount <= 0 or not is_valid_slot(from_index):
        return false
    var source_stack: ItemStack = get_stack_copy(from_index)
    if source_stack == null or source_stack.is_empty():
        return false

    var definition: ItemDefinition = _get_item_definition(source_stack.item_id)
    if definition == null:
        return false

    var item_id: StringName = source_stack.item_id
    var max_stack: int = maxi(definition.max_stack, 1)
    var move_amount: int = mini(amount, source_stack.quantity)
    var available_capacity: int = 0

    for i: int in range(target.get_slot_count()):
        if target == self and i == from_index:
            continue
        var target_stack: ItemStack = target.get_stack_at(i)
        if target_stack == null or target_stack.is_empty():
            available_capacity += max_stack
        elif target_stack.item_id == item_id:
            available_capacity += maxi(max_stack - target_stack.quantity, 0)
        if available_capacity >= move_amount:
            break

    if available_capacity < move_amount:
        return false

    var remaining: int = move_amount
    var changed_target_indices: Array[int] = []
    var transferred_amounts: Array[int] = []

    for i: int in range(target.get_slot_count()):
        if target == self and i == from_index:
            continue
        var target_stack: ItemStack = target.get_stack_copy(i)
        if target_stack == null or target_stack.is_empty() or target_stack.item_id != item_id:
            continue
        var capacity: int = maxi(max_stack - target_stack.quantity, 0)
        if capacity <= 0:
            continue
        var moved: int = mini(remaining, capacity)
        target_stack.quantity += moved
        target._slots[i] = target_stack
        remaining -= moved
        changed_target_indices.append(i)
        transferred_amounts.append(moved)
        if remaining <= 0:
            break

    if remaining > 0:
        for i: int in range(target.get_slot_count()):
            if target == self and i == from_index:
                continue
            var target_stack: ItemStack = target.get_stack_at(i)
            if target_stack != null and not target_stack.is_empty():
                continue
            var moved: int = mini(remaining, max_stack)
            target._slots[i] = ItemStack.new(item_id, moved)
            remaining -= moved
            changed_target_indices.append(i)
            transferred_amounts.append(moved)
            if remaining <= 0:
                break

    source_stack.quantity -= move_amount
    _slots[from_index] = source_stack if source_stack.quantity > 0 else null
    _emit_slot_changed(from_index)

    if target == self:
        _emit_changed_indices(changed_target_indices)
        _emit_container_changed()
    else:
        target._emit_changed_indices(changed_target_indices)
        _emit_container_changed()
        target._emit_container_changed()

    for transfer_index: int in range(changed_target_indices.size()):
        items_transferred.emit(
            from_index,
            target,
            changed_target_indices[transfer_index],
            item_id,
            transferred_amounts[transfer_index]
        )
    return true

func export_slots() -> Array:
    var slots_data: Array = []
    for stack_value: Variant in _slots:
        var stack: ItemStack = stack_value as ItemStack
        slots_data.append(stack.to_dict() if stack != null and not stack.is_empty() else {})
    return slots_data

func import_slots(serialized_slots: Array, target_count: int) -> void:
    configure_slots(target_count)
    var overflow: Array[ItemStack] = []
    for i: int in range(_slots.size()):
        _slots[i] = null
        if i >= serialized_slots.size():
            continue
        var value: Variant = serialized_slots[i]
        if not value is Dictionary:
            continue
        var stack: ItemStack = ItemStack.from_dict(Dictionary(value))
        if stack.is_empty():
            continue
        var definition: ItemDefinition = _get_item_definition(stack.item_id)
        if definition == null:
            continue
        var max_stack: int = maxi(definition.max_stack, 1)
        if stack.quantity > max_stack:
            overflow.append(ItemStack.new(stack.item_id, stack.quantity - max_stack))
        stack.quantity = mini(stack.quantity, max_stack)
        _slots[i] = stack
    for overflow_stack: ItemStack in overflow:
        var remaining: int = add_item(overflow_stack.item_id, overflow_stack.quantity)
        if remaining > 0:
            push_warning("ItemSlotContainerComponent: save import could not restore %d of %s" % [remaining, String(overflow_stack.item_id)])
    for i: int in range(_slots.size()):
        _emit_slot_changed(i)
    _emit_container_changed()

func _get_item_definition(item_id: StringName) -> ItemDefinition:
    var definition: Variant = ContentDB.get_definition(item_id)
    return definition as ItemDefinition

func _resize_slots(target_size: int) -> void:
    if _slots.size() < target_size:
        while _slots.size() < target_size:
            _slots.append(null)
    elif _slots.size() > target_size:
        for i: int in range(target_size, _slots.size()):
            var stack: ItemStack = get_stack_at(i)
            if stack != null and not stack.is_empty():
                push_warning("ItemSlotContainerComponent: refused to shrink occupied slots")
                return
        _slots.resize(target_size)

func _emit_changed_indices(indices: Array[int]) -> void:
    var emitted: Dictionary = {}
    for slot_index: int in indices:
        if emitted.has(slot_index):
            continue
        emitted[slot_index] = true
        _emit_slot_changed(slot_index)

func _emit_slot_changed(slot_index: int) -> void:
    slot_changed.emit(slot_index, get_stack_copy(slot_index))

func _emit_container_changed() -> void:
    container_changed.emit()
