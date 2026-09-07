extends ContentDefinition
class_name ItemDefinition

@export_enum("Material", "Food", "Seed", "Tool", "Equipment", "Consumable", "Special") var category: String = "Material"
@export var icon: Texture2D
@export var max_stack: int = 99
@export var buy_value: int = 0
@export var sell_value: int = 0

func validate_definition() -> PackedStringArray:
    var errors := super.validate_definition()
    if max_stack <= 0:
        errors.append("max_stack must be greater than 0 for %s" % String(content_id))
    if buy_value < 0 or sell_value < 0:
        errors.append("buy_value/sell_value cannot be negative for %s" % String(content_id))
    return errors
