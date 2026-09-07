extends Resource
class_name ResourceDropEntry

@export var item_id: StringName = &""
@export_range(0, 999, 1) var min_amount: int = 1
@export_range(0, 999, 1) var max_amount: int = 1

func roll_amount() -> int:
    var low: int = mini(min_amount, max_amount)
    var high: int = maxi(min_amount, max_amount)
    if high <= 0:
        return 0
    return randi_range(maxi(low, 0), high)

func validate_entry() -> PackedStringArray:
    var errors: PackedStringArray = PackedStringArray()
    if item_id == &"":
        errors.append("ResourceDropEntry is missing item_id")
    elif not (ContentDB.get_definition(item_id) is ItemDefinition):
        errors.append("ResourceDropEntry references unknown/non-item id: %s" % String(item_id))
    if min_amount < 0 or max_amount < 0:
        errors.append("ResourceDropEntry amounts cannot be negative for %s" % String(item_id))
    if max_amount < min_amount:
        errors.append("ResourceDropEntry max_amount is lower than min_amount for %s" % String(item_id))
    return errors
