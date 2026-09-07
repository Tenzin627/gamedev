extends ContentDefinition
class_name LootTableDefinition

@export var entries: Array[ResourceDropEntry] = []

func roll() -> Dictionary:
    var result: Dictionary = {}
    for entry: ResourceDropEntry in entries:
        if entry == null or entry.item_id == &"":
            continue
        var amount: int = entry.roll_amount()
        if amount > 0:
            result[entry.item_id] = int(result.get(entry.item_id, 0)) + amount
    return result

func validate_definition() -> PackedStringArray:
    var errors: PackedStringArray = super.validate_definition()
    if not String(content_id).begins_with("loot."):
        errors.append("Loot table ID should use loot.* namespace")
    if entries.is_empty():
        errors.append("Loot table requires at least one entry")
    for entry: ResourceDropEntry in entries:
        if entry == null:
            errors.append("Loot table contains a non-ResourceDropEntry resource")
        else:
            errors.append_array(entry.validate_entry())
    return errors
