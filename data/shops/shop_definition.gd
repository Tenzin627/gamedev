extends ContentDefinition
class_name ShopDefinition

@export var shopkeeper_npc_id: StringName = &""
@export var stock: Array[ShopStockEntry] = []
@export_range(0.0, 10.0, 0.05) var global_buy_multiplier: float = 1.0
@export_range(0.0, 10.0, 0.05) var global_sell_multiplier: float = 1.0
@export var allow_selling: bool = true

func validate_definition() -> PackedStringArray:
    var errors: PackedStringArray = super.validate_definition()
    if not String(content_id).begins_with("shop."):
        errors.append("Shop ID should use shop.* namespace")
    if shopkeeper_npc_id != &"" and not ContentDB.get_definition(shopkeeper_npc_id) is NPCDefinition:
        errors.append("Unknown shopkeeper NPC: %s" % String(shopkeeper_npc_id))
    for entry: ShopStockEntry in stock:
        if entry == null:
            errors.append("Shop contains null stock entry")
        else:
            errors.append_array(entry.validate_entry())
    return errors
