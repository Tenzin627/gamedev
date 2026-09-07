extends ContentDefinition
class_name TraitDefinition

@export_enum("Attack", "Speed", "Guard") var archetype: String = "Attack"
@export var trigger: StringName = &"none"
@export var effect_ids: Array[StringName] = []
