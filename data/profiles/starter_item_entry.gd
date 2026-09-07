extends Resource
class_name StarterItemEntry

@export var item_id: StringName = &""
@export_range(1, 999, 1) var amount: int = 1
@export_range(-1, 7, 1) var hotbar_slot: int = -1
