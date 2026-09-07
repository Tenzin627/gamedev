extends RefCounted
class_name ItemStack

var item_id: StringName = &""
var quantity: int = 0

func _init(new_item_id: StringName = &"", new_quantity: int = 0) -> void:
    item_id = new_item_id
    quantity = max(new_quantity, 0)

func is_empty() -> bool:
    return item_id == &"" or quantity <= 0

func duplicate_stack() -> ItemStack:
    return ItemStack.new(item_id, quantity)

func to_dict() -> Dictionary:
    if is_empty():
        return {}
    return {
        "item_id": String(item_id),
        "quantity": quantity,
    }

static func from_dict(data: Dictionary) -> ItemStack:
    if data.is_empty():
        return ItemStack.new()
    return ItemStack.new(
        StringName(str(data.get("item_id", ""))),
        max(int(data.get("quantity", 0)), 0)
    )
