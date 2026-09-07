extends Resource
class_name ShopStockEntry

@export var item_id: StringName = &""
@export_range(-1, 999, 1) var stock_limit: int = -1
@export_range(1, 999, 1) var quantity_per_purchase: int = 1
@export_range(0.1, 10.0, 0.05) var buy_price_multiplier: float = 1.0
@export var required_conditions: Array[ContentCondition] = []

func validate_entry() -> PackedStringArray:
    var errors: PackedStringArray = PackedStringArray()
    var item: ItemDefinition = ContentDB.get_definition(item_id) as ItemDefinition
    if item_id == &"" or item == null:
        errors.append("Unknown shop item: %s" % String(item_id))
    if quantity_per_purchase <= 0:
        errors.append("quantity_per_purchase must be positive")
    return errors
