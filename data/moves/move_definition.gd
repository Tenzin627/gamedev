extends ContentDefinition
class_name MoveDefinition

@export_enum("Damage", "Defense", "Buff", "Debuff", "Recovery", "Status", "Control", "Utility") var role: String = "Damage"
@export var power: int = 0
@export var priority: int = 0
@export var effect_ids: Array[StringName] = []
