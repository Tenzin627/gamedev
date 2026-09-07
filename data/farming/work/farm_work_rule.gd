extends Resource
class_name FarmWorkRule

enum Kind { HARVEST, WATER, PLANT, TILL, GATHER_RESOURCE }

@export var kind: Kind = Kind.HARVEST
@export_range(0, 100, 1) var priority: int = 50
@export var enabled: bool = true
