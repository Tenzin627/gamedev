extends Resource
class_name BuildCostEntry

@export var item_id: StringName = &""
@export_range(1, 9999, 1) var amount: int = 1

func validate_cost() -> PackedStringArray:
    var errors: PackedStringArray = PackedStringArray()
    if item_id == &"":
        errors.append("building cost item_id cannot be empty")
    if amount <= 0:
        errors.append("building cost amount must be greater than 0")
    return errors
